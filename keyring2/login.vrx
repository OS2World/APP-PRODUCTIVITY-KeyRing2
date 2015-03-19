/*:VRX         Main
*/
/*  Main
~nokeywords~
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
        CALL Vrmessage "", "Cannot load window: " Vrerror(), , " Error! "
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

/*:VRX         CurrentFileField_ContextMenu
*/
Currentfilefield_contextmenu:
    CALL Fileopenitem_click
RETURN

/*:VRX         CurrentFileField_DragDrop
*/
CurrentFileField_DragDrop: 
    Srcfile = Vrinfo( "SourceFile" )
    IF Srcfile <> "" THEN DO
        Ok = Vrset( "CurrentFileField", "Value", Srcfile )
    END
return

/*:VRX         FileOpenItem_Click
*/
Fileopenitem_click:
    Filename = Vrfiledialog( Vrwindow(), Vlsmsg(229) /* Select a KeyRing/2 database file */, "Open", "*.pwx", , , )
    Ok = Vrset( "CurrentFileField", "Value", Filename )
RETURN

/*:VRX         Fini
*/
Fini:
    CALL Vrset Vrwindow(), "Visible", 0
RETURN Passwordresult

/*:VRX         FlashTimer_Trigger
*/
Flashtimer_trigger:
    Ok = Vrset("PasswordGB", "Visible", 1)
    Ok = Vrset( "KR2LogoGB", "Visible", 1)
    Ok = Vrset("ButtonBox", "Visible", 1)

    Ok = Vrset( "TT_3", "Visible", 0 )
    Ok = Vrset( "TT_3", "Visible", 1 )
    Ok = Vrset( "TT_1", "Visible", 0 )
    Ok = Vrset( "TT_1", "Visible", 1 )

    Ok = Vrset( "FlashTimer", "Enabled", 0)

RETURN


/*:VRX         FlushQueue
*/
Flushqueue:
    DO WHILE Event<>"nop"
        Event=Vrevent("N")
    END
    DROP Event
RETURN

/*:VRX         Halt
*/
Halt:
    SIGNAL _vrehalt
RETURN

/*:VRX         INFHelp
*/
Infhelp:
    ADDRESS Cmd 'start view kr2.inf' Vrget(ARG(1), "UserData")
RETURN

/*:VRX         Init
*/
Init:
    Ok = RXFUNCADD("VLLoadFuncs", "VLMSG", "VLLoadFuncs")/* do not modify or move this line! It must be on line #2 of this function */
    CALL Vlloadfuncs/* do not modify or move this line! It must be on line #3 of this function */

    Ok = RXFUNCADD("KRRLoadFuncs", "KREGISTR", "KRRLoadFuncs")
    CALL KRRloadfuncs

    Ok = KRFN4()

    Ok = Vrredirectstdio("On", "keyring2.err")
    Passwordresult = ""

    Appname = Initargs.1
    Ininame = Initargs.2
    Mode = Initargs.3
    OldPassword = InitArgs.4

    Abort = 0

    Langname = Vrgetini( Appname, "LANGUAGE", Ininame )
    IF Langname = "" THEN DO
        /* default to English on new install */
        Langname = "ENGLISH.MSG"
        Ok = Vrsetini( Appname, "LANGUAGE", Langname, Ininame )
    END
    Ok = Vlopenlang(Langname, Langname)

    Window = Vrwindow()
    CALL Vrmethod Window, "CenterWindow"

    Top = Vrgetini( Appname, "LOGINTOP", Ininame )
    IF Top <> "" THEN do
        Ok = Vrset("Login", "Top", Top)
    end
    DROP Top

    Left = Vrgetini( Appname, "LOGINLEFT", Ininame )
    IF Left <> "" THEN do
        Ok = Vrset("Login", "Left", Left)
    end
    DROP Left

    Width = Vrgetini( Appname, "LOGINWIDTH", Ininame )
    IF Width <> "" THEN do
        Ok = Vrset("Login", "Width", Width)
    end
    DROP Width

    Height = Vrgetini( Appname, "LOGINHEIGHT", Ininame )
    IF Height <> "" THEN do
        Ok = Vrset("Login", "Height", Height)
    end
    DROP Height

    SELECT
        WHEN Mode = "New" THEN DO
            Ok= Vrset("Login", "Caption", Vlsmsg(216) /* KeyRing/2 - Please log in */)
            Ok= Vrset("DT_3", "Caption", Vlsmsg(228) /* Current Database File: */)
            Ok= Vrset("CurrentFileField", "HintText", Vlsmsg(230) /* Current Database filename - Right click for menu. */)
        END
        WHEN Mode = "Save As" THEN DO
            Ok= Vrset("Login", "Caption", Vlsmsg(231) /* KeyRing/2 - Save As */)
            Ok= Vrset("DT_3", "Caption", Vlsmsg(232) /* Save-As File Name: */)
            Ok= Vrset("CurrentFileField", "HintText", Vlsmsg(233) /* Select a new name;  Right click for menu. */)
        END
        OTHERWISE DO
        END
    END

    CALL Vrset Window, "Visible", 0
    CALL Vrmethod Window, "Activate"
    DROP Window

    Ok = Vrset( "PasswordHintField", "Value", Vrgetini( Appname, "HINT", Ininame ) )
    Ok = Vrset( "CurrentFileField", "Value", Vrgetini( Appname, "DB", Ininame ) )

    IF Vrgetini( Appname, "DB", Ininame ) = "" THEN DO
        Filename = Vrfiledialog( Vrwindow(), Vlsmsg(234) /* Please enter a new password database file name */, "Save", "*.PWX", , , )
        Ok = Vrset( "CurrentFileField", "Value", Filename )
        Ok = Vrsetini( Appname, "DB", Filename, Ininame )
        IF Filename <> "" THEN DO
            Ok = Vrmethod( "Password_Field", "SetFocus" )
        END
    END
        ELSE DO
            IF Vrfileexists(Vrgetini( Appname, "DB", Ininame )) = 1 THEN
                Ok = Vrmethod( "Password_Field", "SetFocus" )
                ELSE
                    Ok = Vrmethod( "CurrentFileField", "SetFocus" )
        END
    CALL Login_langinit


    Buttons.1 = VLSMsg(124) /* ~Ok */
    Buttons.2 = VLSMsg(140) /* Quit */
    Buttons.3 = VLSMsg(355) /* Help */
    Buttons.0 = 3

    do while KRFN9() = 0
        id = VRPrompt( VRWindow(), VLSMsg(356) /* Please enter your registration code (see README.REG) */, "RegCode", VLSMsg(358) /* Error! Missing or invalid Registration Code */, "Buttons.", 1, 2 )
        if id = 2 then do
            call Quit
            leave
        end
        if id = 3 then do
            ADDRESS Cmd 'start view kr2.inf ' Product Registration Overview
        end
        Ok = KRFN1(RegCode)
    end

RETURN

/*:VRX         Login_Close
*/
Login_close:
    CALL Quit
RETURN

/*:VRX         Login_Create
*/
Login_create:
    Ok = Vrset( "ModeDT", "Caption", Krgetcrypttype() || " " || KRFN8() )
RETURN

/*:VRX         Login_Help
*/
Login_help:
    CALL Infhelp(Vrinfo("Source"))
RETURN





/*:VRX         Login_LangException
*/
Login_LangException: 

return

/*:VRX         Login_LangInit
*/
Login_LangInit:

    /* ------------------------------------------------ */
    /* Language internationalization code autogenerated */
    /* by VXNation v1.0, Copyright 1999, IDK, Inc.      */
    /*          http://www.idk-inc.com                  */
    /* Autogenerated: 03/06/2000 19:23:52             */
    /* ------------------------------------------------ */
    /* Warning! This code gets overwritten by VXNation! */
    /* Do not make modifications here!                  */
    /* ------------------------------------------------ */

    /* Keyring/2 Login */
    Ok = VRSet("Login", "WindowListTitle", VLSMsg(215))

    /* KeyRing/2 - Please log in */
    Ok = VRSet("Login", "Caption", VLSMsg(216))

    /* ~Ok */
    Ok = VRSet("OkButton", "Caption", VLSMsg(124))

    /* Open Current Database File using the Master Password */
    Ok = VRSet("OkButton", "HintText", VLSMsg(217))

    /* Cancel */
    Ok = VRSet("QuitButton", "Caption", VLSMsg(218))

    /* Abort KeyRing/2 */
    Ok = VRSet("QuitButton", "HintText", VLSMsg(219))

    /* Timer */
    Ok = VRSet("FlashTimer", "Caption", VLSMsg(66))

    /* Encryption type message goes here */
    Ok = VRSet("ModeDT", "Caption", VLSMsg(220))

    /* Master Password: */
    Ok = VRSet("DT_1", "Caption", VLSMsg(223))

    /* Enter your master password or phrase - case sensitive */
    Ok = VRSet("Password_Field", "HintText", VLSMsg(224))

    /* Hint: */
    Ok = VRSet("DT_2", "Caption", VLSMsg(225))

    /* Hint to remind you of your master password (make it obscure) */
    Ok = VRSet("PasswordHintField", "HintText", VLSMsg(226))

    /* Current Database filename - Right click for menu */
    Ok = VRSet("CurrentFileField", "HintText", VLSMsg(227))

    /* Current Database File: */
    Ok = VRSet("DT_3", "Caption", VLSMsg(228))

    /* Timer */
    Ok = VRSet("TM_1", "Caption", VLSMsg(66))

    call Login_LangException
    DROP Ok

RETURN

/*:VRX         Login_Resize
*/
Login_resize:

    CALL Vrset Vrwindow(), "Visible", 1
    CALL Flushqueue

    Height = Vrget( "Login", "Height" )
    Width = Vrget( "Login", "Width" )

    Ok = Vrset("KR2LogoGB", "Visible", 0)
    Ok = Vrset("PasswordGB", "Visible", 0)
    Ok = Vrset("ButtonBox", "Visible", 0)

    IF (Height-3175) > 100 THEN do
        Ok = Vrset("PasswordGB", "Height", Height - 3175 )
	end

    Ok = Vrmethod("PasswordGB", "UpdateLayout" )

    IF (Height - 5300) > 100 THEN do
        Ok = Vrset("PasswordHintField", "Height", Height - 5300 )
	end

    Ok = Vrset("ButtonBox", "Top", Height - 1200 )
    Ok = Vrmethod("ButtonBox", "UpdateLayout" )

    Ok = Vrset( "PasswordGB", "Width", Width - 100 )
    Ok = Vrset( "KR2LogoGB", "Width", Width - 100 )
    Ok = Vrset( "ButtonBox", "Width", Width - 100 )

    Ok = Vrset( "CurrentFileField", "Width", Width - 350 )
    Ok = Vrset( "Password_Field", "Width", Width - 350 )
    Ok = Vrset( "PasswordHintField", "Width", Width - 350 )

    Ok = Vrset( "Description", "Width", Width - 3500 )
    Ok = Vrset( "ModeDT", "Width", Width - 3500 )

    Ok = Vrset( "FlashTimer", "Enabled", 1 )
    Ok = Vrset( "FlashTimer", "Delay", 250 )
RETURN
/*:VRX         OkButton_Click
*/
Okbutton_click:
    
    Passwordresult = Vrget("Password_Field", "Value")
    IF LENGTH(Passwordresult) < 4 THEN DO
        if Mode = "Save As" then do
            PasswordResult = OldPassword
            Buttons.1 = VLSMsg(124) /* ~Ok */
            Buttons.0 = 1
            id = VRMessage( VRWindow(), VLSMsg(374) /* Save As aborted; Using old password and database. */, VLSMsg(153) /* Note: */, "Information", "Buttons.", 1, 1 )
            call quit
            return
        end
        Buttons.1 = Vlsmsg(80)                                  /* Ok */
        Buttons.0 = 1
        Id = Vrmessage( Vrwindow(), Vlsmsg(260) /* Invalid password! */, Vlsmsg(86) /* Warning */, "Warning", "Buttons.", 1, 1 )
        Ok = Vrmethod( "Password_Field", "SetFocus" )
        RETURN
    END
    if Mode = "Save As" then do
        IF PassWordResult <> OldPassword then do
            Lines.1 = VLSMsg(375) /* You have changed the master password for this database! */
            Lines.2 = ""
            Lines.3 = VLSMsg(376) /* Select Use New Password to change the master password to the one you just entered. */
            Lines.4 = VLSMsg(377) /* Select Use Old Password to reuse the old password */
            Lines.0 = 4
            Buttons.1 = VLSMsg(378) /* Use ~New Password */
            Buttons.2 = VLSMsg(379) /* Use ~Old Password */
            Buttons.0 = 2
            id = VRMessageStem( VRWindow(), "Lines.", VLSMsg(120) /* Warning! */, "Warning", "Buttons.", 2, 2 )
            if id = 2 then do
                Ok = vrset("password_field", "Value", OldPassword)
                return
            end
        end
    end
    Value = Vrget( "CurrentFileField", "Value" )
    IF Value = "" THEN DO
        Buttons.1 = Vlsmsg(80)                                  /* Ok */
        Buttons.0 = 1
        Id = Vrmessage( Vrwindow(), Vlsmsg(261) /* Invalid Database Filename! */, Vlsmsg(86) /* Warning */, "Warning", "Buttons.", 1, 1 )
        Ok = Vrmethod( "CurrentFileField", "SetFocus" )
        RETURN
    END
    IF Vrfileexists( Value ) = 0 THEN DO
        Lines.1 = Vrexpandfilename( Value ) || Vlsmsg(262)/*  does not exist. */
        Lines.2 = Vlsmsg(263)          /* Creating new database file. */
        Lines.0 = 2
        Buttons.1 = Vlsmsg(80)                                  /* Ok */
        Buttons.0 = 1
        Id = Vrmessagestem( Vrwindow(), "Lines.", "Info", Vlsmsg(111) /* Information */, "Buttons.", 1, 1 )
    END
    Value = Krgetcrypttype()
    if Abbrev(Value, "NON") = 1 then do
        Lines.1 = VLSMsg(380) /* You are missing the encryption module! */
        Lines.2 = VLSMsg(381) /* If you proceed, your secrets will be stored in a readable format and will not be usable by the full product. */
        Lines.3 = VLSMsg(382) /* Email kr2@idk-inc.com for details on obtaining an encryption module. */
        Lines.0 = 3
        Buttons.1 = VLSMsg(383) /* Ignore warning and proceed */
        Buttons.2 = VLSMsg(140) /* Quit */
        Buttons.0 = 2
        id = VRMessageStem( VRWindow(), "Lines.", VLSMsg(384) /* Warning! Warning! Warning! */, "Warning", "Buttons.", 2, 2 )
        if id = 2 then do
            Passwordresult = ""
        end
    end
    CALL Quit
RETURN

/*:VRX         Pict_1_Click
*/
Pict_1_click:
    Ok = About(Vrwindow(), Appname, Ininame)
RETURN

/*:VRX         Quit
*/
Quit:
    Ok = Vrsetini( Appname, "HINT", Vrget( "PasswordHintField", "Value" ), Ininame )
    Ok = Vrsetini( Appname, "DB", Vrget("CurrentFileField", "Value"), Ininame )
    Ok = Vrsetini( Appname, "LOGINTOP", Vrget("Login", "Top"), Ininame )
    Ok = Vrsetini( Appname, "LOGINLEFT", Vrget("Login", "Left"), Ininame )
    Ok = Vrsetini( Appname, "LOGINWIDTH", Vrget("Login", "Width"), Ininame )
    Ok = Vrsetini( Appname, "LOGINHEIGHT", Vrget("Login", "Height"), Ininame )
    CALL Vrset Vrwindow(), "Shutdown", 1
RETURN

/*:VRX         QuitButton_Click
*/
Quitbutton_click:
    Passwordresult = ""
    CALL Quit
RETURN

/*:VRX         TM_1_Trigger
*/
TM_1_Trigger: 
    Value = KRFN4()
return

/*:VRX         TT_1_Click
*/
Tt_1_click:
    Ok = About(Vrwindow(), Appname, Ininame)
RETURN

/*:VRX         TT_3_Click
*/
Tt_3_click:
    Ok = About(Vrwindow(), Appname, Ininame)
RETURN


