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

/*:VRX         __VXREXX____APPENDS__
*/
__VXREXX____APPENDS__:
/*
#append G:\keyring2\SHARED.VRX
*/
return
/*:VRX         AddRec
*/
AddRec: 
    Contindx = ARG(1)
    Myicon = ARG(2)

    AppName = "KR2"
    IniName = "KR2.INI"

    if MyIcon = "" then do
        MyIcon = "$1"
    end

    Cont = Contnames.contindx || "Container"
    Recordhandle = Vrmethod( Cont, "AddRecord", , "Last", Vlsmsg(286) /* New */, MyIcon, , )
    Ok = Vrmethod( Cont, "GetFieldList", "Fields." )

    /* now set up some of the default fields in the record */
    Ok = Vrmethod( Cont, "SetRecordAttr", Recordhandle, "Icon", MyIcon)
    Ok = Vrmethod( Cont, "SetRecordAttr", Recordhandle, "Caption", Vlsmsg(286) /* New */ )

    I = Getfieldindex(Contindx, "I")          /* get extra icon field */
    Ok = Vrmethod( Cont, "SetFieldData", Recordhandle, Fields.i, MyIcon )

    I = Getfieldindex(Contindx, "D")         /* get description field */
    Ok = Vrmethod( Cont, "SetFieldData", Recordhandle, Fields.i, Vlsmsg(286) /* New */ )

    /* set column order field */
    Value = Getorder(Contindx)
    Ok = Vrmethod( Cont, "SetFieldData", Recordhandle, Fields.10, Value)

    /* now edit the puppy */
    Editresult = Editrec(Vrwindow(), Vrget(Cont, "Self" ), Recordhandle, Contindx, Appname, Ininame)

    IF Editresult <> 1 THEN DO
        /* user abort or error */
        Ok = Vrmethod(Cont, "RemoveRecord", Recordhandle)
    END
    ELSE DO
        DirtyFlag = 1
        Ok = Vrmethod( Cont, "Arrange" )
    END

    DROP Editvals Ok Contindx Cont
RETURN 1


/*:VRX         ClipContainer_DragDiscard
*/
ClipContainer_DragDiscard: 

return

/*:VRX         ClipContainer_DragDrop
*/
ClipContainer_DragDrop: 
    Record = Vrinfo( "SourceRecord" )
    Container = Vrinfo("SourceObject")
    Target = VRInfo("TargetObject")
    
    IF Record = "" THEN DO
        RETURN
    END

    Caption = Vrmethod( Container, "GetRecordAttr", Record, "Caption" )
    Icon = Vrmethod( Container, "GetRecordAttr", Record, "Icon" )

    ok = VRMethod( Container, "GetFieldList", "Fields." )
    say "************"
    DO I = 1 TO FIELDS.0 
        say  VRMethod( Container, "GetFieldAttr", Fields.i, "Title" )
        say  VRMethod( Container, "GetFieldAttr", Fields.i, "Name" )
        say "----------"

        /* fieldHandle = VRMethod( "ClipContainer", "AddField", "String", "title" ) */
        
    END

    recordHandle = VRMethod( "ClipContainer", "AddSharedRecord", Record, , "First" )

    ok = VRMethod( Container, "RemoveRecord", Record )

    return    

    IF Srcfile = "" THEN DO
        /* icon from internal container */
        Value = Vrmethod( Container, "GetRecordAttr", Record, "Icon" )
    END
        ELSE DO
            /* icon file dropped */
            Value = Srcfile
        END

    IF Targrec <> "" THEN DO
        /* dropped on existing record */
        /* change the icon view icon */
        Ok= Vrmethod(Vrinfo("TargetObject"), "SetRecordAttr", Targrec, "Icon", Value)
        /* change the icon field (for details view) */
        Ok = Vrmethod( Vrinfo("TargetObject"), "SetFieldData", Targrec, Getfieldname(2, "I"), Value)
    END
        ELSE DO
            /* dropped on empty space */
            /* Create new record using the dropped icon */
            Ok = Addrec(2, Value)
        END

return

/*:VRX         CloseButton_Click
*/
CloseButton_Click: 
    Call quit
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

/*:VRX         Init
*/
Init:
    Ok = RXFUNCADD("VLLoadFuncs", "VLMSG", "VLLoadFuncs")/* do not modify or move this line! It must be on line #2 of this function */
    CALL Vlloadfuncs/* do not modify or move this line! It must be on line #3 of this function */

    Ok = Vrredirectstdio("On", "keyring2.err")
    Appname = Initargs.1
    Ininame = Initargs.2

    Langname = Vrgetini( Appname, "LANGUAGE", Ininame )
    IF Langname = "" THEN DO
        Langname = "ENGLISH.MSG"
    END
    Ok = Vlopenlang(Langname, Langname)

    Window = Vrwindow()
    CALL Vrmethod Window, "Activate"

    Font = Vrgetini( Appname, "RECCLIPFONT", Ininame )
    IF Font <> "" THEN DO
        Ok = Vrmethod( "RECCLIP", "ListChildren", "ObjList." )
        DO I = 1 TO Objlist.0
            IF Vrmethod( "Application", "SupportsProperty", Objlist.i , "Font" ) = 1 THEN DO
                Ok = Vrset(Objlist.i, "Font", Font)
            END
        END
    END

    Ok = Vrset( "ClipContainer", "MiniIcons", 0 )
    Contname = "ClipContainer"

    Iconhandle = Vrmethod( "ClipContainer", "AddField", "Icon", "Icon", "IconField")

    Lastwid = 0
    Lasthyt = 0
    Height = Vrgetini( Appname, "RECCLIPHEIGHT", Ininame )
    IF Height <> "" THEN DO
        Ok = Vrset( "RECCLIP", "Height", Height)
        Ok = Vrset( "RECCLIP", "Width", Vrgetini( Appname, "RECCLIPWIDTH", Ininame ))
        Ok = Vrset( "ClipContainer", "Font", Vrgetini( Appname, "RECCLIPFONT", Ininame ) )
        Ok = Vrset( "RECCLIP", "Left", Vrgetini( Appname, "RECCLIPLEFT", Ininame ))
        Ok = Vrset( "RECCLIP", "Top", Vrgetini( Appname, "RECCLIPTOP", Ininame ))
    END
    ELSE DO
        CALL Vrmethod Window, "CenterWindow"
    END
    call RECCLIP_LangInit

    CALL RECCLIP_resize
    CALL Vrset Window, "Visible", 1

    DROP Items
    DROP Window
    Contnames.0 = 1
    Contnames.1 = "Clip" 

/*
    fieldHandle = VRMethod( "ClipContainer", "AddField", "Icon", "F1" )
    fieldHandle = VRMethod( "ClipContainer", "AddField", "String", "F2" )
    fieldHandle = VRMethod( "ClipContainer", "AddField", "String", "F3" )
    fieldHandle = VRMethod( "ClipContainer", "AddField", "String", "F4" )
    fieldHandle = VRMethod( "ClipContainer", "AddField", "String", "F5" )
    fieldHandle = VRMethod( "ClipContainer", "AddField", "String", "F6" )
    fieldHandle = VRMethod( "ClipContainer", "AddField", "String", "F7" )
    fieldHandle = VRMethod( "ClipContainer", "AddField", "String", "F8" )
    fieldHandle = VRMethod( "ClipContainer", "AddField", "String", "F9" )
    fieldHandle = VRMethod( "ClipContainer", "AddField", "String", "Order" )
*/ 
    /* zzzz
    IniLoaded = 0  
    Ok = ContainerInit(1)
    CALL Container_langinit(1)
    */
    CALL Restoreprops
    ClipWininited = 1
    CALL NormalMouse
return

/*:VRX         Quit
*/
Quit:
    Ok = Vrsetini( Appname, "RECCLIPHEIGHT", Vrget("RECCLIP", "Height"), Ininame )
    Ok = Vrsetini( Appname, "RECCLIPWIDTH", Vrget("RECCLIP", "Width"), Ininame )
    Ok = Vrsetini( Appname, "RECCLIPFONT", Vrget("ClipContainer", "Font"), Ininame )
    Ok = Vrsetini( Appname, "RECCLIPLEFT", Vrget("RECCLIP", "Left"), Ininame )
    Ok = Vrsetini( Appname, "RECCLIPTOP", Vrget("RECCLIP", "Top"), Ininame )
    Window = Vrwindow()
    CALL Vrset Window, "Shutdown", 1
    DROP Window
return

/*:VRX         RECCLIP_Close
*/
RECCLIP_Close:
    call Quit
return

/*:VRX         RECCLIP_LangInit
*/
RECCLIP_LangInit: 

return

/*:VRX         RECCLIP_Resize
*/
RECCLIP_Resize: 
    Ok = Vrset( "TM_1", "Enabled", 1 )
    Ok = Vrset( "TM_1", "Delay", 500 )
    Ok = Vrset( "GB_1", "Visible", 0 )
    Ok = Vrset( "GB_2", "Visible", 0 )
    ok = VRSet( "CloseButton", "Visible", 0 )

    Width = Vrget( "RecClip", "Width" )
    Height = Vrget( "RecClip", "Height" )
    IF Height > 3600 THEN DO
        Gbtop = Height - 1350
        Ok = Vrset("GB_2", "Top", Gbtop)
        Ok = VRSet( "CloseButton", "Top", GBTop + 150 )
        Gb1hyt = Height - 1451
        Ok = Vrset( "GB_1", "Height", Gb1hyt )
        Ok = Vrset( "ClipContainer", "Height", Gb1hyt-241 )
    END
    IF Width > 2244 THEN DO
        Gb1w = Width - 217
        Ok = Vrset( "GB_1", "Width", Gb1w )
        Ok = Vrset("GB_2", "Width", Gb1w)
        Ok = Vrset( "ClipContainer", "Width", Gb1w - 241 )
    END

    IF Lasthyt <> Height THEN DO
        Ok = Vrmethod( "ClipContainer", "Arrange" )
    END
        ELSE DO
            IF Lastwid <> Width THEN DO
                Ok = Vrmethod( "ClipContainer", "Arrange" )
            END
        END

    Lasthyt = Height
    Lastwid = Width

return

/*:VRX         TM_1_Trigger
*/
TM_1_Trigger: 
    Ok = Vrset( "TM_1", "Enabled", 0 )
    Ok = Vrset( "GB_1", "Visible", 1 )
    Ok = Vrset( "GB_2", "Visible", 1 )
    ok = VRSet( "CloseButton", "Visible", 1 )
return

