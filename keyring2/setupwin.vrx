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
        CALL Vrmessage "", Vlsmsg(78) /* Cannot load window: */ Vrerror(), ,
            Vlsmsg(79)                                      /* Error! */
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

/*:VRX         AppPageName_ContextMenu
*/
AppPageName_ContextMenu: 
    call SetPgHint(2)
return

/*:VRX         BrowserNameField_ContextMenu
*/
Browsernamefield_contextmenu:
    CALL Browsersearchbutton_click
RETURN

/*:VRX         BrowserSearchButton_Click
*/
Browsersearchbutton_click:
    Filename = Vrfiledialog( Vrwindow(), vlsmsg(277) /* Browser EXE */, "Open", "*.EXE", , , )
    Ok = Vrset( "BrowserNameField", "Value", Filename )
RETURN

/*:VRX         ComboPageName_ContextMenu
*/
ComboPageName_ContextMenu: 
    call SetPgHint(4)
return

/*:VRX         CustomFontCB_Click
*/
CustomFontCB_Click: 
    Ok = Vrsetini( Appname, Vrget(Vrinfo("Object"), "Name"), Vrget(Vrget(Vrinfo("Object"), "Name"), "Set"), Ininame )
return

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
    call SaveFields
RETURN 0


/*:VRX         GetPageHint
*/
GetPageHint: 
    Value = KRGetPageHint(Arg(2))
    IF Value = "" THEN DO
        Value = VLSMsg(ARG(1))
    END
return Value

/*:VRX         Halt
*/
Halt:
    SIGNAL _vrehalt
RETURN

/*:VRX         HandleInhibitClick
*/
Handleinhibitclick:
/*
*/
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

    Ok = VRRedirectStdIO("On", "keyring2.err")
    Appname = Initargs.1
    Ininame = Initargs.2

    /* NB page prefixes for containers */
    Contnames.1 = "WWW"
    Contnames.2 = "App"
    Contnames.3 = "PIN"
    Contnames.4 = "Combo"
    Contnames.5 = "Other1"
    Contnames.6 = "Other2"
    Contnames.0 = 6

    /* NB Page names for columns */
    ColNames.1 = "Icon"
    ColNames.2 = "Desc"
    ColNames.3 = "Password"
    ColNames.4 = "Userid"
    ColNames.5 = "SN"
    ColNames.6 = "LastUpdate"
    ColNames.7 = "ExpDate"
    ColNames.8 = "URL"
    ColNames.9 = "Note"

    /* Enable Button nouns */
    EnbName.1 = "Icon"
    EnbName.2 = "Desc"
    EnbName.3 = "Pw"
    EnbName.4 = "User"
    EnbName.5 = "SN"
    EnbName.6 = "LastUpd"
    EnbName.7 = "Exp"
    EnbName.8 = "URL"
    EnbName.9 = "Note"
    
    do I = 1 to 6
      PgHint.i = GetPageHint(277+I, I)
    END

    Langname = Vrgetini( Appname, "LANGUAGE", Ininame )
    IF Langname = "" THEN DO
        Langname = "ENGLISH.MSG"
    END
    Ok = Vlopenlang(Langname, Langname)

    Window = Vrwindow()
    CALL Vrmethod Window, "CenterWindow"
    CALL Vrset Window, "Visible", 1
    CALL Vrmethod Window, "Activate"
    CALL Waitmouse
    DROP Window
/*
    Ok = Vrmethod( Vrget(Vrwindow(), "name"), "ListChildren", "child." )

    Lastchild=Child.0+1
    Child.lastchild= Vrget(Vrwindow(), "name")
    Child.0=Lastchild
    Initstring=""
    DO X=1 TO Child.0
        Value = Vrgetini( Appname, Vrget(Child.x, Name), Ininame, "NOCLOSE" )
        IF Value <> "" THEN DO
            IF Vrmethod( "Application", "SupportsProperty", Child.x , "Set" ) = 1 THEN DO
                Ok = Vrset(Child.x, "Set", Value)
            END
        END
    END
*/
    do i = 1 to 6
        do j = 1 to 9 
            Ok = VRSet(ContNames.I || EnbName.J || "CB", "Set", KRGetPageEnable(I, J))
        end
    end
    
    do i = 1 to 6
        ok = VRSet( ContNames.i || "PageName", "Value", VLSMsg(240+I) )
        ok = VRSet( ContNames.i || "IconColumnName", "Value", VLSMsg(99) /* Icon */ )
        ok = VRSet( ContNames.i || "DescColumnName", "Value", VLSMsg(100) /* Description */ )
        ok = VRSet( ContNames.i || "PasswordColumnName", "Value", VLSMsg(101) /* Password */ )
        ok = VRSet( ContNames.i || "UserIDColumnName", "Value",  VLSMsg(102) /* User */)
        ok = VRSet( ContNames.i || "SNColumnName", "Value", VLSMsg(103) /* S/N */ )
        ok = VRSet( ContNames.i || "LastUpdateColumnName", "Value",  VLSMsg(104) /* Last Update */)
        ok = VRSet( ContNames.i || "ExpDateColumnName", "Value",  VLSMsg(105) /* Exp Date */ )
        ok = VRSet( ContNames.i || "URLColumnName", "Value",  VLSMsg(106) /* URL */)
        ok = VRSet( ContNames.i || "NoteColumnName", "Value", VLSMsg(107) /* Note */ )
    end

    do i = 1 to 6
        Value = KRGetPageName(I)
        if Value <> "" THEN DO
            ok = VRSet( ContNames.i || "PageName", "Value", Value )
        END
        do j = 1 to 9 
            Value = KRGetColumnName(i, j)
            if Value <> "" then do
                Ok = VRSet( ContNames.i || ColNames.j || "ColumnName", "Value", Value)
            end
        end
    end

    Ok = Vrset( "BrowserNameField", "Value", Vrgetini( Appname, "BrowserApp", Ininame) )
    Ok = Vrset("CustomFontCB","Set", VrGetIni(AppName, "CustomFontCB", IniName))
    I = VRGetIni( AppName, "BackupGenerationSpinner", IniName )
    Ok = VRSet( "BackupGenerationSpinner", "Value", I )

    CALL Normalmouse
    DROP X Ok Child I J
    CALL Setupwin_langinit
RETURN

/*:VRX         NormalMouse
*/
Normalmouse:
    CALL Vrset Vrwindow(), "Pointer", "<default>"/* show "normal" mouse pointer */
RETURN

/*:VRX         Other1PageName_ContextMenu
*/
Other1PageName_ContextMenu: 
    call SetPgHint(5)
return

/*:VRX         Other2PageName_ContextMenu
*/
Other2PageName_ContextMenu: 
    call SetPgHint(6)
return

/*:VRX         PG1_ContextMenu
*/
PG1_ContextMenu: 
    call savefields
    Ok = ColOrd(VRWindow(), VRInfo("Source"))
return

/*:VRX         PG2_ContextMenu
*/
PG2_ContextMenu: 
    call savefields
    Ok = ColOrd(VRWindow(), VRInfo("Source"))

return

/*:VRX         PG3_ContextMenu
*/
PG3_ContextMenu: 
    call savefields
    Ok = ColOrd(VRWindow(), VRInfo("Source"))

return

/*:VRX         PG4_ContextMenu
*/
PG4_ContextMenu: 
    call savefields
    Ok = ColOrd(VRWindow(), VRInfo("Source"))

return

/*:VRX         PG5_ContextMenu
*/
PG5_ContextMenu: 
    call savefields
    Ok = ColOrd(VRWindow(), VRInfo("Source"))

return

/*:VRX         PG6_ContextMenu
*/
PG6_ContextMenu: 
    call savefields
    Ok = ColOrd(VRWindow(), VRInfo("Source"))

return

/*:VRX         PINPageName_ContextMenu
*/
PINPageName_ContextMenu: 
    call SetPgHint(3)
return

/*:VRX         Quit
*/
Quit:
    Window = Vrwindow()
    CALL Vrset Window, "Shutdown", 1
    DROP Window
RETURN

/*:VRX         SaveFields
*/
SaveFields: 
    call waitmouse
    Value = Vrget( "BrowserNameField", "Value" )
    Ok = Vrsetini( Appname, "BrowserApp", Value, Ininame )

    ok = VRSetIni( AppName, "CustomFontCB", VRGet( "CustomFontCB", "Set" ), IniName )

    ok = VRSetIni( AppName, "BackupGenerationSpinner", VRGet( "BackupGenerationSpinner", "Value" ), IniName )

    do i = 1 to 6
        Ok = KRPutPageName(I, VRGet( ContNames.I || "PageName", "Value" ))
        Ok = KrPutPageHint(I, PgHint.I)
        do j = 1 to 9 
            Value = VRGet( ContNames.i || ColNames.J || "ColumnName", "Value" )
            Ok = KRPutColumnName(I, J, Value)
            Ok = KRPutPageEnable(I, J, VRGet(ContNames.I || EnbName.J || "CB", "Set"))
        end
    end
    call normalmouse
return

/*:VRX         SetPgHint
*/
SetPgHint: 
    PARSE ARG Pg
    Value = PgHint.Pg
    Buttons.1 = "Ok"
    Buttons.2 = "Cancel"
    Buttons.0 = 2
    id = VRPrompt( VRWindow(), "Enter a description (Help Hint) for this page. ", "Value", "Enter Hint", "Buttons.", 1, 2 )
    if ID = 1 then do
        PgHint.Pg = Value
    end
return

/*:VRX         SetupWin_Close
*/
Setupwin_close:
    CALL Quit
RETURN

/*:VRX         SetupWin_Help
*/
SetupWin_Help: 
    CALL Infhelp(Vrinfo("Source"))
return


/*:VRX         SetupWin_LangInit
*/
SetupWin_LangInit:

    /* ------------------------------------------------ */
    /* Language internationalization code autogenerated */
    /* by VXNation v1.0, Copyright 1999, IDK, Inc.      */
    /*          http://www.idk-inc.com                  */
    /* Autogenerated: 12/10/1999 09:29:34             */
    /* ------------------------------------------------ */
    /* Warning! This code gets overwritten by VXNation! */
    /* Do not make modifications here!                  */
    /* ------------------------------------------------ */


    DROP Ok

RETURN

/*:VRX         UseDefaultsButton_Click
*/
UseDefaultsButton_Click: 
    Buttons.1 = VLSMsg(124) /* ~Ok */
    Buttons.2 = VLSMsg(218) /* Cancel */
    Buttons.0 = 2
    id = VRMessage( VRWindow(), VLSMsg(1) /* Are you sure you want to lose all your changes (if any)? */, VLSMsg(86) /* Warning */, "Warning", "Buttons.", 2, 2 )
    if ID = 1 then do
        do i = 1 to 6
            ok = VRSet( ContNames.i || "PageName", "Value", VLSMsg(240+I) )
            ok = VRSet( ContNames.i || "IconColumnName", "Value", VLSMsg(99) /* Icon */ )
            ok = VRSet( ContNames.i || "DescColumnName", "Value", VLSMsg(100) /* Description */ )
            ok = VRSet( ContNames.i || "PasswordColumnName", "Value", VLSMsg(101) /* Password */ )
            ok = VRSet( ContNames.i || "UserIDColumnName", "Value",  VLSMsg(102) /* User */)
            ok = VRSet( ContNames.i || "SNColumnName", "Value", VLSMsg(103) /* S/N */ )
            ok = VRSet( ContNames.i || "LastUpdateColumnName", "Value",  VLSMsg(104) /* Last Update */)
            ok = VRSet( ContNames.i || "ExpDateColumnName", "Value",  VLSMsg(105) /* Exp Date */ )
            ok = VRSet( ContNames.i || "URLColumnName", "Value",  VLSMsg(106) /* URL */)
            ok = VRSet( ContNames.i || "NoteColumnName", "Value", VLSMsg(107) /* Note */ )
            PgHint.I = VLSMsg(I + 277)        
        end
    end
return

/*:VRX         WaitMouse
*/
Waitmouse:
    CALL Vrset Vrwindow(), "Pointer", "Wait"/* show "Busy" mouse pointer */
RETURN

/*:VRX         WWWPageName_ContextMenu
*/
WWWPageName_ContextMenu: 
    call SetPgHint(1)
return

