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

/*:VRX         __VXREXX____APPENDS__
*/
__VXREXX____APPENDS__:
/*
#append G:\keyring2\SHARED.VRX
*/
return
/*:VRX         AddBackSlash
*/
Addbackslash:
    Strg = ARG(1)
    IF Strg <> "" THEN DO 
        IF SUBSTR(Strg, LENGTH(Strg)) <> '\' THEN do
            Strg = Strg || '\'
        end
    END
RETURN Strg

/*:VRX         AddRec_Click
*/
AddRec_Click: 
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

/*:VRX         AppContainer_ContextMenu
*/
Appcontainer_contextmenu:
    CALL Vrmethod "AppEditMenu", "popup"
RETURN

/*:VRX         AppContainer_DoubleClick
*/
Appcontainer_doubleclick:
    CALL Edititem
RETURN

/*:VRX         AppContainer_DragDiscard
*/
AppContainer_DragDiscard: 
    CALL DragDiscard
return

/*:VRX         AppContainer_DragDrop
*/
Appcontainer_dragdrop:
    Record = Vrinfo( "Record" )
    Srcfile = Vrinfo( "SourceFile" )
    Container = Vrinfo("SourceObject")
    Targrec = Vrinfo("TargetRecord")

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

RETURN

/*:VRX         AppDetailRB_Click
*/
Appdetailrb_click:
    /* zzzz enable sort menu */
    Ok = Vrsetini( Appname, "VIEW2", 2, Ininame )
    Ok = Sortarrange(2)
RETURN

/*:VRX         AppEditItemClick_Click
*/
Appedititemclick_click:
    CALL Edititem
RETURN

/*:VRX         AppIconRB_Click
*/
Appiconrb_click:
    /* zzzz disable sort menu */
    Ok = Vrsetini( Appname, "VIEW2", 1, Ininame )
    Ok = Sortarrange(2)
RETURN

/*:VRX         AppLargeIconRB_Click
*/
Applargeiconrb_click:
    Ok = Vrset( "AppContainer", "MiniIcons", 0 )
    Ok = Vrsetini( Appname, "MINI2", 0, Ininame )
    CALL Sortarrange(2)
RETURN

/*:VRX         AppNewButton_Click
*/
Appnewbutton_click:
    CALL Addrec(2)
RETURN

/*:VRX         AppSmallIconRB_Click
*/
Appsmalliconrb_click:
    Ok = Vrset( "AppContainer", "MiniIcons", 1 )
    Ok = Vrsetini( Appname, "MINI2", 1, Ininame )
    CALL Sortarrange(2)
RETURN

/*:VRX         AppWin_Close
*/
Appwin_close:
    CALL Saveprops
    CALL Appwin_fini
RETURN

/*:VRX         AppWin_Create
*/
Appwin_create:
    CALL Appwin_init
RETURN

/*:VRX         AppWin_Fini
*/
Appwin_fini:
    Window = Vrinfo( "Window" )
    CALL Vrdestroy Window
    DROP Window
RETURN
/*:VRX         AppWin_Help
*/
Appwin_help:
        
    CALL Infhelp(Vrinfo("Source"))
RETURN

/*:VRX         AppWin_Init
*/
Appwin_init:
    CALL AppWin_LangInit /* do not modify or move this line! It must be on line #1 of this function */
    
    Window = Vrinfo( "Object" )
    /*
    IF( \Vrischildof( Window, "Notebook" ) ) THEN DO
        CALL Vrmethod Window, "CenterWindow"
        /* CALL Vrset Window, "Visible", 1 */
        CALL Vrmethod Window, "Activate"
    END
    */
    CALL Containerinit(2)
    CALL Container_langinit(2)
    CALL Restoreprops
    Appwininited = 1
    DROP Window
RETURN





/*:VRX         AppWin_LangException
*/
AppWin_LangException:
    call SetTickLabels(2) 
    do I = 1 to 6
        Ok = VRSet("MoveToPg" || i, "Caption", Getpagename(240 + I, I))
        Ok = VRSet("CopyToPg" || i, "Caption", Getpagename(240 + I, I))
    end
return

/*:VRX         AppWin_LangInit
*/
AppWin_LangInit:

    /* ------------------------------------------------ */
    /* Language internationalization code autogenerated */
    /* by VXNation v1.0, Copyright 1999, IDK, Inc.      */
    /*          http://www.idk-inc.com                  */
    /* Autogenerated: 03/06/2000 19:08:43             */
    /* ------------------------------------------------ */
    /* Warning! This code gets overwritten by VXNation! */
    /* Do not make modifications here!                  */
    /* ------------------------------------------------ */

    /* Application passwords and registration codes */
    Ok = VRSet("AppWin", "HintText", VLSMsg(42))

    /* Application Codes */
    Ok = VRSet("AppContainer", "Caption", VLSMsg(43))

    /* List of application passwords and registration codes */
    Ok = VRSet("AppContainer", "HintText", VLSMsg(279))

    /* timer */
    Ok = VRSet("AppWinFlashTimer", "Caption", VLSMsg(45))

    /* I'm a logo! */
    Ok = VRSet("Pg2Icon", "HintText", VLSMsg(156))

    /* ;Dsc;Upd;Usr;S/N;Pw;Icon */
    MyTick.1 = VLSMsg(235)
    MyTick.2 = VLSMsg(236)
    MyTick.3 = VLSMsg(237)
    MyTick.4 = VLSMsg(103)
    MyTick.5 = VLSMsg(239)
    MyTick.6 = VLSMsg(99)
    MyTick.0 = 6
/*
    Ok = VRMethod("AppSortSlide", "SetTickLabels", "MyTick.")
*/
    DROP MyTick.

    /* Change Address sort order */
/*
    Ok = VRSet("AppSortSlide", "HintText", VLSMsg(46))
*/
    /* ~Large Icons */
    Ok = VRSet("AppLargeIconRB", "Caption", VLSMsg(47))

    /* Selects Large icon size */
    Ok = VRSet("AppLargeIconRB", "HintText", VLSMsg(48))

    /* ~Small Icons */
    Ok = VRSet("AppSmallIconRB", "Caption", VLSMsg(49))

    /* Selects Small icon size */
    Ok = VRSet("AppSmallIconRB", "HintText", VLSMsg(72))

    /* ~Icon View */
    Ok = VRSet("AppIconRB", "Caption", VLSMsg(50))

    /* Select icon view of application codes */
    Ok = VRSet("AppIconRB", "HintText", VLSMsg(51))

    /* ~Detail View */
    Ok = VRSet("AppDetailRB", "Caption", VLSMsg(52))

    /* Select details view of application codes */
    Ok = VRSet("AppDetailRB", "HintText", VLSMsg(53))

    /* ~New */
    Ok = VRSet("AppNewButton", "Caption", VLSMsg(54))

    /* Click to create a new record */
    Ok = VRSet("AppNewButton", "HintText", VLSMsg(75))

    /* AppEdit */
    Ok = VRSet("AppEditMenu", "Caption", VLSMsg(55))

    /* Edit Item(s) */
    Ok = VRSet("AppEditItemClick", "Caption", VLSMsg(56))

    /* {Enter} */
    Ok = VRSet("AppEditItemClick", "Accelerator", VLSMsg(57))

    /* Add Item */
    Ok = VRSet("AppAddRec", "Caption", VLSMsg(58))

    /* Delete Item(s) */
    Ok = VRSet("AppDelItem", "Caption", VLSMsg(59))

    /* - */
    Ok = VRSet("Menu1", "Caption", VLSMsg(24))

    /* Copy Password to Clipboard */
    Ok = VRSet("Pass2Clip", "Caption", VLSMsg(60))

    /* Copy Username to Clipboard */
    Ok = VRSet("NameToClip", "Caption", VLSMsg(390))

    /* - */
    Ok = VRSet("Menu2", "Caption", VLSMsg(24))

    /* Open URL in Netscape */
    Ok = VRSet("URLItem", "Caption", VLSMsg(61))

    /* - */
    Ok = VRSet("Menu3", "Caption", VLSMsg(24))

    /* Move Items(s) to another page */
    Ok = VRSet("Menu4", "Caption", VLSMsg(391))

    /* Copy Items(s) to another page */
    Ok = VRSet("Menu5", "Caption", VLSMsg(393))

    /* Sort */
    Ok = VRSet("Menu6", "Caption", VLSMsg(394))

    call AppWin_LangException
    DROP Ok

RETURN

/*:VRX         AppWin_Resize
*/
Appwin_resize: PROCEDURE EXPOSE Lastheight Lastwidth
    IF Vrget( "DataNB", "Selected" ) <> 2 THEN DO
        RETURN
    END

    Ok = ContainerResize("App", 2)
RETURN


/*:VRX         AppWinFlashTimer_Trigger
*/
Appwinflashtimer_trigger:
    Ok = Vrset("AppContainer", "Visible", 0)
    Ok = Vrmethod( "AppContainer", "SortRecords" )
    Ok = Vrmethod( "AppContainer", "Arrange" )

    CALL Appwin_langinit
    CALL Container_langinit(2)
    Ok = Vrset( "AppWinFlashTimer", "Enabled", 0)
    Ok = Vrset( "AppControlGB", "Visible", 1)

    CALL Setcolumnvisibility(2)
    Ok = Vrset("AppContainer", "Visible", 1)
    Ok = Vrset("AppContainerGB", "Visible", 1)

RETURN

/*:VRX         Bosswin_Close
*/
Bosswin_close:
    CALL Saveprops
    CALL Bosswin_fini
RETURN

/*:VRX         Bosswin_Create
*/
Bosswin_create:
    CALL Bosswin_init
RETURN

/*:VRX         Bosswin_DragDrop
*/
Bosswin_DragDrop: 
    Srcfile = Vrinfo( "SourceFile" )
    Suffix = Translate(VRParseFileName( SrcFile, "E" ))
    if Suffix <> "BMP" THEN DO
        Buttons.1 = "Ok"
        Buttons.0 = 1
        id = VRMessage( VRWindow(), "Invalid file type!  You must use OS/2 BMP files!", "Warning", "Warning", "Buttons.", 1, 1 )
        return
    end
    ok = VRSetIni( "KR2", "BOSSBMP", SrcFile, "KR2.INI" )
    ok = VRSet( "BossWin", "PicturePath", SrcFile )
return


/*:VRX         Bosswin_Fini
*/
Bosswin_fini:
    Window = Vrinfo( "Window" )
    CALL Vrdestroy Window
    DROP Window
RETURN
/*:VRX         Bosswin_Help
*/
Bosswin_help:
    CALL Infhelp(Vrinfo("Source"))
RETURN

/*:VRX         Bosswin_Init
*/
Bosswin_init:
    CALL Bosswin_LangInit /* do not modify or move this line! It must be on line #1 of this function */
    CALL Restoreprops
    CALL Seticons
    Ok = Vrset( "DataNB", "Visible", 1 )
    SrcFile = VRGetIni( "KR2", "BOSSBMP", "KR2.INI" )
    if SrcFile <> "" THEN DO
        ok = VRSet( "BossWin", "PicturePath", SrcFile )
    END
    CALL Killhat
RETURN





/*:VRX         Bosswin_LangException
*/
Bosswin_LangException: 

return

/*:VRX         Bosswin_LangInit
*/
Bosswin_LangInit:

    /* ------------------------------------------------ */
    /* Language internationalization code autogenerated */
    /* by VXNation v1.0, Copyright 1999, IDK, Inc.      */
    /*          http://www.idk-inc.com                  */
    /* Autogenerated: 03/06/2000 19:08:44             */
    /* ------------------------------------------------ */
    /* Warning! This code gets overwritten by VXNation! */
    /* Do not make modifications here!                  */
    /* ------------------------------------------------ */

    /* Use this page to quickly hide your secrets when someone walks in the room. */
    Ok = VRSet("Bosswin", "HintText", VLSMsg(285))

    call Bosswin_LangException
    DROP Ok

RETURN

/*:VRX         Bosswin_Resize
*/
Bosswin_resize:
RETURN

/*:VRX         BrowseNewURL
*/
Browsenewurl:
    Url = ARG(1)

    /*
    CALL Vrmethod "Application", "SendKeyString", S, "{Tab}{Tab}{Tab}{Tab}"
    CALL Vrmethod "Application", "SendKeyString", S, "zzzzz{Enter}"
    */

    /* Netscape browser must be up and running at this point */
    Ok = Vrmethod("DDEC_1", "Accept", Gettopicindex("Netscape", "WWW_OpenURL"))
    Data.0 = 0
    Ok = Vrmethod( "DDEC_1", "RequestList", Url || ',,0xFFFFFFFF', "data.")
    DROP Data.

    Ok = Vrmethod( "DDEC_1", "Terminate" )

    /*
    CALL Vrmethod "Application", "SendKeyString", S, "{Tab}{Tab}{Tab}{Tab}"
    CALL Vrmethod "Application", "SendKeyString", S, "zzzzz{Enter}"
    */
RETURN 1

/*:VRX         BrowserButton_Click
*/
Browserbutton_click:
    Badpage = 0
    Curpage = Vrget( "DataNB", "Selected" )
    IF Curpage < Contnames.0 THEN DO
        Prefix = Contnames.curpage
    END
        ELSE DO
            Badpage = 1
        END

    IF Badpage = 1 THEN DO
        Buttons.1 = Vlsmsg(80)                                  /* Ok */
        Buttons.0 = 1
        Id = Vrmessage( Vrwindow(), Vlsmsg(89) /* There are no URLs here! */, Vlsmsg(82) /* Info */, "Information", "Buttons.", , )
        DROP Buttons Id
        RETURN
    END
        ELSE DO
            Rec = Getsingleselitem(Prefix)
        END

    IF Rec <> "" THEN DO
        Url = Vrmethod( Prefix || "Container", "GetFieldData", Rec, Getfieldname(Curpage, "U"))
        IF Url = "" THEN DO
            Buttons.1 = Vlsmsg(80)                              /* Ok */
            Buttons.0 = 1
            Id = Vrmessage( Vrwindow(), Vlsmsg(90) /* There is no URL associated with this item! */, Vlsmsg(82) /* Info */, "Information", "Buttons.", , )
            DROP Buttons Id
            RETURN
        END
            ELSE DO
                Value = Vrgetini( Appname, "BrowserApp", Ininame )
                IF Value = "" THEN DO
                    Buttons.1 = Vlsmsg(80)                      /* Ok */
                    Buttons.0 = 1
                    Id = Vrmessage( Vrwindow(), Vlsmsg(91) /* There is no specified browser! */, Vlsmsg(82) /* Info */, "Information", "Buttons.", , )
                    DROP Buttons Id
                    CALL Setupitem_click
                    RETURN
                END

                S = Scanwindows()
                IF S = "" THEN DO
                    Ok = Vrredirectstdio( On, "" )
                    ADDRESS Cmd "Start " || VALUE || ' "' || Url || '"'
                    S = ""
                    CALL Waitforbrowser
                    Ok = Vrredirectstdio( OFF, "" )
                END
                    ELSE DO
                        CALL Browsenewurl(Url)
                    END
            END
    END
RETURN


/*:VRX         BrowserTimer_ContextMenu
*/
Browsertimer_contextmenu:
    CALL Vrmethod "TimerMenu", "popup"
RETURN

/*:VRX         BrowserTimer_Trigger
*/
Browsertimer_trigger:
    Ok = Vrset( "BrowserTimer", "Visible", 1)
    Lasttime = Lasttime -1
    IF Lasttime > -1 THEN DO
        Ok = Vrset( "BrowserTimer", "Caption", Lasttime )
        S = Scanwindows()
        IF S <> "" THEN DO
            Ok = Vrset( "BrowserTimer", "Enabled", 0 )
            Ok = Vrset( "BrowserTimer", "Visible", 0)
            CALL Browsenewurl(Url)
        END
    END
        ELSE DO
            Ok = Vrset( "BrowserTimer", "Enabled", 0 )
            Ok = Vrset( "BrowserTimer", "Visible", 0)
            Buttons.1 = Vlsmsg(80)                              /* Ok */
            Buttons.0 = 1
            Id = Vrmessage( Vrwindow(), Vlsmsg(92) /* Netscape failed to launch! */, Vlsmsg(93) /* Error */, "Error", "Buttons.", , )
            DROP Buttons Id
        END
    DROP Ok
RETURN

/*:VRX         CCalc
*/
Ccalc:
    Crc = ARG(1)
    Strg = ARG(2)
    DO Index = 1 TO LENGTH(Strg)
        Crc = Krarea52(SUBSTR(Strg, Index, 1), Crc)
    END
RETURN Crc

/*:VRX         ChangeLang_Click
*/
Changelang_click:
    Filename = Vrfiledialog( Vrwindow(), Vlsmsg(252) /* Select a new screen language */, "Open", "*.MS?", , , )
    Ok = Vlchangelang(Filename, Filename)
    IF Ok = 1 THEN DO
        Ok = Vrsetini( Appname, "LANGUAGE", Filename, Ininame )
    END
    CALL Langchanged     
RETURN

/*:VRX         CheckExpiredButton_Click
*/
Checkexpiredbutton_click:
    ok = VRSet( "CheckExpiredButton", "Enabled", 0 )
    CALL Waitmouse
    CALL Updatetree
    CALL Waitmouse
    Value = Krgetexpiredrec(1, "", "", "", "", "", "", "", "", "", "", "", "", "")
    IF Value = "0" THEN DO
        CALL Normalmouse
        Buttons.1 = Vlsmsg(80)                                  /* Ok */
        Buttons.0 = 1
        Id = Vrmessage( Vrwindow(), Vlsmsg(287) /* No expired records found! */, Vlsmsg(82) /* Info */, "Information", "Buttons.", , )
        ok = VRSet( "CheckExpiredButton", "Enabled", 1 )
        RETURN
    END
    CALL Normalmouse
    Ok = Expired(Vrwindow(), Appname, Ininame)
    call waitmouse
    Ok = Vrset( "DataNB", "Visible", 0 )
    call waitmouse
    CALL Reinitpages
    call waitmouse
    CALL Restoreprops
    call waitmouse
    CALL Settabs
    call waitmouse
    Ok = Vrset( "DataNB", "Visible", 1 )
    ok = VRSet( "CheckExpiredButton", "Enabled", 1 )
    CALL Normalmouse
RETURN

/*:VRX         CheckFileAndPw
*/
Checkfileandpw:
    IF LENGTH( Password ) < 4 THEN DO
        Buttons.1 = Vlsmsg(80)                                  /* Ok */
        Buttons.0 = 1
        Id = Vrmessage( Vrwindow(), Vlsmsg(94) /* Password is too short! */, Vlsmsg(79) /* Error! */, "Error", "Buttons.", , )
        RETURN 0
    END

    IF Iniloaded THEN DO
        /* file already loaded - this should never happen */
        RETURN 1
    END

    Filename = Vrgetini( Appname, "DB", Ininame )

    Ext = VRParseFilePath( Filename, "E" )
    if translate(ext) = "PWC" then do
        Buttons.1 = Vlsmsg(80)                                  /* Ok */
        Buttons.0 = 1
        id = VRMessage( VRWindow(), VLSMsg(368) /* Please use the Import feature for PWC files */, VLSMsg(86) /* Warning */, "Warning", "Buttons.", 1, 1 )
        return 0
    end
    
    CALL Launchhat

    IF Filename = "" THEN DO
        /* Oktokillhat = 1 */
        CALL Killhat
        RETURN 0
    END

    Ok = Kropenini(Filename, Password)
    SELECT
        WHEN Ok = 0 THEN DO
            /* should never get here*/
        END
        WHEN Ok = 1 THEN DO
            /* Success */
            Oldfilename = Filename
            Iniloaded = 1
        END
        WHEN Ok = 99 THEN DO
            CALL Killhat
            /* Expired EXE */
            Buttons.1 = Vlsmsg(95)                          /* Byebye */
            Buttons.0 = 1
            Id = Vrmessage( Vrwindow(), Vlsmsg(96) /* Product Expired! */, Vlsmsg(97) /* Errorrrrr! */, "Error", "Buttons.", , )
            Iniloaded = 0
        END
        WHEN Ok = 100 THEN DO
            /* New PWX created */
            Oldfilename = Filename
            Ok = SetDefaultView()
            Iniloaded = 1
        END
        WHEN Ok = 207 THEN DO
            CALL Killhat
            /* Expired PWX */
            Buttons.1 = Vlsmsg(95)                          /* Byebye */
            Buttons.0 = 1
            Id = Vrmessage( Vrwindow(), Vlsmsg(329) /* Database Expired! */, Vlsmsg(97) /* Errorrrrr! */, "Error", "Buttons.", , )
            Iniloaded = 0
        END
        OTHERWISE DO                                           /* 200 */
            CALL Killhat
            Iniloaded = 0
            Buttons.1 = Vlsmsg(80)                              /* Ok */
            Buttons.0 = 1
            Id = Vrmessage( Vrwindow(), Vlsmsg(98) /* Invalid Password */, Vlsmsg(79) /* Error! */, "Error", "Buttons.", , )
            DROP Prompt Buttons Id
        END
    END
        value = Iniloaded

RETURN Value

/*:VRX         ComboContainer_ContextMenu
*/
Combocontainer_contextmenu:
    CALL Vrmethod "ComboEditMenu", "popup"
RETURN

/*:VRX         ComboContainer_DoubleClick
*/
Combocontainer_doubleclick:
    CALL Edititem
RETURN

/*:VRX         ComboContainer_DragDiscard
*/
ComboContainer_DragDiscard: 
    CALL DragDiscard
return

/*:VRX         ComboContainer_DragDrop
*/
Combocontainer_dragdrop:
    Record = Vrinfo( "Record" )
    Srcfile = Vrinfo( "SourceFile" )
    Container = Vrinfo("SourceObject")
    Targrec = Vrinfo("TargetRecord")

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
        Ok = Vrmethod( Vrinfo("TargetObject"), "SetFieldData", Targrec, Getfieldname(4, "I"), Value)
    END
        ELSE DO
            /* dropped on empty space */
            /* Create new record using the dropped icon */
            Ok = Addrec(4, Value)
        END

RETURN

/*:VRX         ComboDelItem_Click
*/
ComboDelItem_Click:
    Ok = Vrmethod( Vrinfo("Source"), "GetRecordList", "Selected", "SelectedRecs." )
    IF Selectedrecs.0 = 0 THEN DO
        Buttons.1 = Vlsmsg(80)                                  /* Ok */
        Buttons.0 = 1
        Id = Vrmessage( Vrwindow(), Vlsmsg(81) /* No items selected for deletion */, Vlsmsg(82) /* Info */, "Information", "Buttons.", , )
        DROP Buttons Selectedrecs
        RETURN
    END
    Buttons.1 = Vlsmsg(83)                                     /* Yes */
    Buttons.2 = Vlsmsg(84)                                      /* No */
    Buttons.0 = 2
    IF Selectedrecs.0 = 1 THEN do
        Id = Vrmessage( Vrwindow(), Vlsmsg(85) /* Are you sure you want to delete this item? */, Vlsmsg(86) /* Warning */, "Information", "Buttons.", 2, 2 )
    end
    ELSE do
            Id = Vrmessage( Vrwindow(), Vlsmsg(87) /* Are you sure you want to delete these  */ || Selectedrecs.0 || Vlsmsg(88) /*  items? */, Vlsmsg(86) /* Warning */, "Information", "Buttons.", 2, 2 )
    end
    IF Id = 1 THEN DO
        DirtyFlag = 1
        DO I = 1 TO Selectedrecs.0
            Ok = Vrmethod( Vrinfo("Source"), "RemoveRecord", Selectedrecs.i )
        END
    END
    DROP Selectedrecs I Buttons

RETURN

/*:VRX         ComboDetailRB_Click
*/
Combodetailrb_click:
    /* zzzz enable sort menu */
    Ok = Vrsetini( Appname, "VIEW4", 2, Ininame )
    Ok = Sortarrange(4)
RETURN

/*:VRX         ComboIconRB_Click
*/
Comboiconrb_click:
    /* zzzz disable sort menu */
    Ok = Vrsetini( Appname, "VIEW4", 1, Ininame )
    Ok = Sortarrange(4)
RETURN

/*:VRX         ComboLargeIconRB_Click
*/
Combolargeiconrb_click:
    Ok = Vrset( "ComboContainer", "MiniIcons", 0 )
    Ok = Vrsetini( Appname, "MINI4", 0, Ininame )
    CALL Sortarrange(4)
RETURN

/*:VRX         ComboNewButton_Click
*/
Combonewbutton_click:
    CALL Addrec(4)
RETURN

/*:VRX         ComboSmallIconRB_Click
*/
Combosmalliconrb_click:
    Ok = Vrset( "ComboContainer", "MiniIcons", 1 )
    Ok = Vrsetini( Appname, "MINI4", 1, Ininame )
    CALL Sortarrange(4)
RETURN

/*:VRX         ComboWin_Close
*/
Combowin_close:
    CALL Saveprops
    CALL Combowin_fini
RETURN

/*:VRX         ComboWin_Create
*/
Combowin_create:
    CALL Combowin_init
RETURN

/*:VRX         ComboWin_Fini
*/
Combowin_fini:
    Window = Vrinfo( "Window" )
    CALL Vrdestroy Window
    DROP Window
RETURN
/*:VRX         ComboWin_Help
*/
Combowin_help:
    CALL Infhelp(Vrinfo("Source"))
RETURN

/*:VRX         ComboWin_Init
*/
Combowin_init:
    CALL ComboWin_LangInit /* do not modify or move this line! It must be on line #1 of this function */
    Window = Vrinfo( "Object" )
    /*
    IF( \Vrischildof( Window, "Notebook" ) ) THEN DO
        CALL Vrmethod Window, "CenterWindow"
        CALL Vrset Window, "Visible", 1
        CALL Vrmethod Window, "Activate"
    END
    */
    CALL Containerinit(4)
    CALL Container_langinit(4)
    CALL Restoreprops
    Combowininited = 1
    DROP Window
RETURN





/*:VRX         ComboWin_LangException
*/
ComboWin_LangException: 
    call SetTickLabels(4) 
return

/*:VRX         ComboWin_LangInit
*/
ComboWin_LangInit:

    /* ------------------------------------------------ */
    /* Language internationalization code autogenerated */
    /* by VXNation v1.0, Copyright 1999, IDK, Inc.      */
    /*          http://www.idk-inc.com                  */
    /* Autogenerated: 03/06/2000 19:08:43             */
    /* ------------------------------------------------ */
    /* Warning! This code gets overwritten by VXNation! */
    /* Do not make modifications here!                  */
    /* ------------------------------------------------ */

    /* Lock/Safe combinations */
    Ok = VRSet("ComboWin", "HintText", VLSMsg(70))

    /* Lock combinations */
    Ok = VRSet("ComboContainer", "Caption", VLSMsg(71))

    /* List of safe and lock combinations */
    Ok = VRSet("ComboContainer", "HintText", VLSMsg(281))

    /* Timer */
    Ok = VRSet("ComboWinFlashTimer", "Caption", VLSMsg(66))

    /* ;Dsc;Upd;Usr;S/N;Pw;Icon */
    MyTick.1 = VLSMsg(235)
    MyTick.2 = VLSMsg(236)
    MyTick.3 = VLSMsg(237)
    MyTick.4 = VLSMsg(103)
    MyTick.5 = VLSMsg(239)
    MyTick.6 = VLSMsg(99)
    MyTick.0 = 6
/*
    Ok = VRMethod("ComboSortSlide", "SetTickLabels", "MyTick.")
    DROP MyTick.

    Ok = VRSet("ComboSortSlide", "HintText", VLSMsg(46))
*/
    /* ~Large Icons */
    Ok = VRSet("ComboLargeIconRB", "Caption", VLSMsg(47))

    /* Selects Large icon size */
    Ok = VRSet("ComboLargeIconRB", "HintText", VLSMsg(48))

    /* ~Small Icons */
    Ok = VRSet("ComboSmallIconRB", "Caption", VLSMsg(49))

    /* Selects Small icon size */
    Ok = VRSet("ComboSmallIconRB", "HintText", VLSMsg(72))

    /* ~Icon View */
    Ok = VRSet("ComboIconRB", "Caption", VLSMsg(50))

    /* Select icon view of application codes */
    Ok = VRSet("ComboIconRB", "HintText", VLSMsg(51))

    /* ~Detail View */
    Ok = VRSet("ComboDetailRB", "Caption", VLSMsg(52))

    /* Select details view of application codes */
    Ok = VRSet("ComboDetailRB", "HintText", VLSMsg(53))

    /* I'm a logo! */
    Ok = VRSet("Pg4Icon", "HintText", VLSMsg(156))

    /* ~New */
    Ok = VRSet("ComboNewButton", "Caption", VLSMsg(54))

    /* Click to create a new record */
    Ok = VRSet("ComboNewButton", "HintText", VLSMsg(75))

    call ComboWin_LangException
    DROP Ok

RETURN

/*:VRX         ComboWin_Resize
*/
Combowin_resize: PROCEDURE EXPOSE Lastheight Lastwidth
    IF Vrget( "DataNB", "Selected" ) <> 4 THEN DO
        RETURN
    END
    Ok = ContainerResize("Combo", 4)
RETURN

/*:VRX         ComboWinFlashTimer_Trigger
*/
Combowinflashtimer_trigger:
    Ok = Vrset("ComboContainer", "Visible", 0)
    Ok = Vrmethod( "ComboContainer", "SortRecords" )
    Ok = Vrmethod( "ComboContainer", "Arrange" )

    CALL Combowin_langinit
    CALL Container_langinit(4)
    Ok = Vrset( "ComboWinFlashTimer", "Enabled", 0)

    Ok = Vrset( "ComboControlGB", "Visible", 1)

    CALL Setcolumnvisibility(4)
    Ok = Vrset("ComboContainer", "Visible", 1)
    Ok = Vrset("ComboContainerGB", "Visible", 1)
RETURN

/*:VRX         ContainerResize
*/
ContainerResize: 
    MyCont = ARG(1)
    ContIndex = ARG(2)

    Ok = Vrset( MyCont || "ContainerGB", "Visible", 0)
    Ok = Vrset( MyCont || "ControlGB", "Visible", 0)
    Ok = Vrset( MyCont || "Container", "Visible", 0 )

    Ok = Vrset( MyCont || "winFlashTimer", "Enabled", 1 )
    Ok = Vrset( MyCont || "winFlashTimer", "Delay", 500 )

    Height = Vrget( MyCont || "win", "Height" )
    Width = Vrget( MyCont || "win", "Width" )

    IF Height = Lastheight.ContIndex THEN DO
        IF Width = Lastwidth.ContIndex THEN DO
            say "same size"
            RETURN
        END
    END

    Lastheight.ContIndex = Height
    Lastwidth.ContIndex = Width

    Ok = Vrset( MyCont || "ContainerGB", "Width", Width - 200 )
    Ok = Vrset( MyCont || "Container", "Width", Width - 500 )
    Ok = Vrset( MyCont || "ControlGB", "Width", Width - 200 )
    Tstfudge = 600
    Vtstfudge = 300

    Ok = Vrset( MyCont || "ContainerGB", "Height", Height - 1578 - Tstfudge )
    Ok = Vrset( MyCont || "ControlGB", "Top", Height - 1378- Tstfudge )
    Ok = Vrset( MyCont || "Container", "Height", Height - 1878 - Tstfudge)

    /* ok, so now we calculate dynamic sizes of of the sub boxes of the control group */

    /* now set the horizontal sizes and coordinates */

    Controlgap = 109
    Textlead = 120

    Tw = MAX(Vrget( MyCont || "IconRB", "Width" ), Vrget( MyCont || "DetailRB", "Width" ))

    Ok = Vrset( MyCont || "ViewGB", "Width", Tw + (Textlead * 2))
    L = Vrget(MyCont || "ViewGB", "Left")                
    R = L + Tw + (Textlead * 2)                  

    Ok = Vrset( MyCont || "IconSizeGB", "Left", R + Controlgap )
    L = R + Controlgap                           
    Tw = MAX(Vrget( MyCont || "LargeIconRB", "Width" ), Vrget( MyCont || "SmallIconRB", "Width" ))
    Ok = Vrset(MyCont || "IconSizeGB", "Width", Tw + (Textlead * 2))
    R = L + Tw + (Textlead * 2)                  
    L = R + Controlgap

    NewGBLeft = L
    /* set left side of AppNewButtonGB */
    Ok = Vrset( MyCont || "NewButtonGB", "Left", L )

    /* calc button width */
    Font = Vrget( MyCont || "NewButton", "Font" )
    Ok = Vrset( "DummyDT", "Font", Font )
    Ok = Vrset( "DummyDT", "Caption", Vlsmsg(54) /* ~New */)
    Tw = Vrget( "DummyDT", "Width" )

    Ok = Vrset( MyCont || "NewButton", "Width", Tw + (Textlead * 2))

    /* now calc the logo width */
    Tw = VRGet( MyCont || "LogoGB", "Width" )
    L = Width - Tw - (ControlGap * 3)
    Ok = VRSet( MyCont || "LogoGB", "Left", L)

    Ok = Vrset( MyCont || "NewButtonGB", "Width", L - NewGBLeft - ControlGap)

    /* now set the vertical sizes and coordinates */
    Boxhyt.1 = Textlead + Vrget( MyCont || "IconRB", "Height" ) + Textlead + Vrget(MyCont || "DetailRB", "Height") + Textlead
    Ok = Vrset( MyCont || "IconRB", "Top", Textlead )
    Ok = Vrset( MyCont || "DetailRB", "Top", Textlead + Vrget( MyCont || "IconRB", "Height" ) + Textlead)

    Boxhyt.2 = Textlead + Vrget( MyCont || "LargeIconRB", "Height" ) + Textlead + Vrget(MyCont || "SmallIconRB", "Height") + Textlead
    Ok = Vrset( MyCont || "LargeIconRB", "Top", Textlead )
    Ok = Vrset( MyCont || "SmallIconRB", "Top", Textlead + Vrget( MyCont || "LargeIconRB", "Height" ) + Textlead)

    Ok = Vrset( "DummyDT", "Font", Font )
    Ok = Vrset( "DummyDT", "Caption", "XXX")
    Th = Vrget( "DummyDT", "Height" )

    Font = Vrget( MyCont || "NewButton", "Font" )
    Ok = Vrset( "DummyDT", "Font", Font )
    Ok = Vrset( "DummyDT", "Caption", "XXX")
    Th = Vrget( "DummyDT", "Height" )
    Boxhyt.4 = Controlgap + Textlead + Th + Textlead + Controlgap

    Bh = MAX(Boxhyt.1, Boxhyt.2, Boxhyt.4)

    Ok = Vrset(MyCont || "ViewGB", "Height", Bh)
    Ok = Vrset(MyCont || "IconSizeGB", "Height", Bh)
    Ok = Vrset(MyCont || "NewButtonGB", "Height", Bh)
    Ok = Vrset(MyCont || "LogoGB", "Height", Bh)

    Ok = Vrset(MyCont || "ControlGB", "Height", Bh + (Controlgap * 2))

    Bh = Bh + (Controlgap * 2)              /* hight of control group */

    Ok = Vrset( MyCont || "ContainerGB", "Height", Height - Bh - Controlgap - Vtstfudge)
    Ok = Vrset( MyCont || "ControlGB", "Top", Height - Bh - Vtstfudge )
    Ok = Vrset( MyCont || "Container", "Height", Height - Bh - (Controlgap * 4) - Vtstfudge)
return 1

/*:VRX         Containers_LangInit
*/
Containers_langinit:
    DO Index = 1 TO 6
        CALL Container_langinit(Index)
    END
RETURN

/*:VRX         CopyItemsToPage
*/
CopyItemsToPage: PROCEDURE EXPOSE Contnames. DirtyFlag 
    SourcePage = Vrget( "DataNB", "Selected" )
    DestPage = arg(1)

    SourceCont = Contnames.SourcePage || "Container" /* get the current container name */
    DestCont = Contnames.DestPage || "Container" /* get destination container name */

    ok = VRMethod( SourceCont, "GetFieldList", "SourceFields." )
    ok = VRMethod( DestCont, "GetFieldList", "DestFields." )

    /* get selected item(s) and move them in-turn */
    Ok = Vrmethod( SourceCont, "GetRecordList", "Selected", Selectedrecs. )

    SourceOrder = Getorder(SourcePage)
    DestOrder = GetOrder(DestPage)

    IF Selectedrecs.0 > 0 THEN DO
        DirtyFlag = 1
        DO Indx = 1 TO Selectedrecs.0
            /* get the stuff we need to create the initial icon */
            Icon = GetFieldVal(SourcePage, "I", SelectedRecs.Indx)
            Caption = GetFieldVal(SourcePage, "D", SelectedRecs.Indx)

            /* create new record in destination container */
            recordHandle = VRMethod( DestCont, "AddRecord", , "Last", Caption, Icon, ,  )

            /* set column order field */
            Ok = Vrmethod( DestCont, "SetFieldData", Recordhandle, DestFields.10, DestOrder)

            /* copy all the fields over */
            Ok = SetFieldVal(DestPage, recordHandle, "I", GetFieldVal(SourcePage, "I", SelectedRecs.Indx))
            Ok = SetFieldVal(DestPage, recordHandle, "D", GetFieldVal(SourcePage, "D", SelectedRecs.Indx))
            Ok = SetFieldVal(DestPage, recordHandle, "N", GetFieldVal(SourcePage, "N", SelectedRecs.Indx))
            Ok = SetFieldVal(DestPage, recordHandle, "P", GetFieldVal(SourcePage, "P", SelectedRecs.Indx))
            Ok = SetFieldVal(DestPage, recordHandle, "S", GetFieldVal(SourcePage, "S", SelectedRecs.Indx))
            Ok = SetFieldVal(DestPage, recordHandle, "L", GetFieldVal(SourcePage, "L", SelectedRecs.Indx))
            Ok = SetFieldVal(DestPage, recordHandle, "E", GetFieldVal(SourcePage, "E", SelectedRecs.Indx))
            Ok = SetFieldVal(DestPage, recordHandle, "U", GetFieldVal(SourcePage, "U", SelectedRecs.Indx))
            Ok = SetFieldVal(DestPage, recordHandle, "W", GetFieldVal(SourcePage, "W", SelectedRecs.Indx))

            /* delete the old record from the source container */
            /* ok = VRMethod( SourceCont, "RemoveRecord", Selectedrecs.indx ) */
            DirtyFlag = 1
        END
    END
        ELSE DO
            Buttons.1 = Vlsmsg(80)                              /* Ok */
            Buttons.0 = 1
            Id = Vrmessage( Vrwindow(), Vlsmsg(110) /* You must first select one or more items. */, Vlsmsg(111) /* Information */, "Information", "Buttons.", , )
            DROP Selectedrecs Id Buttons
        END
return 1

/*:VRX         CopyToPg1_Click
*/
CopyToPg1_Click: 
    Ok = CopyItemsToPage(1)
return

/*:VRX         CopyToPg2_Click
*/
CopyToPg2_Click: 
    Ok = CopyItemsToPage(2)

return

/*:VRX         CopyToPg3_Click
*/
CopyToPg3_Click: 
    Ok = CopyItemsToPage(3)

return

/*:VRX         CopyToPg4_Click
*/
CopyToPg4_Click: 
    Ok = CopyItemsToPage(4)

return

/*:VRX         CopyToPg5_Click
*/
CopyToPg5_Click: 
    Ok = CopyItemsToPage(5)

return

/*:VRX         CopyToPg6_Click
*/
CopyToPg6_Click: 
    Ok = CopyItemsToPage(6)

return

/*:VRX         DataNB_PageSelected
*/
Datanb_pageselected:
    Curpage = Vrget("DataNB", "Selected")
    IF Curpage = 7 THEN DO
        /* use gray wheel button */
        Ok = Vrset( "BrowserButton", "PicturePath", "#968:kricon.dll" )
        Ok = Vrset( "BrowserButton", "Enabled", 0 )

    END
        ELSE DO
            /* use normal wheel button */
            Ok = Vrset( "BrowserButton", "PicturePath", "#962:kricon.dll" )
            Ok = Vrset( "BrowserButton", "Enabled", 1)
        END

    Pwok = Getfieldstatus(Curpage, "P")
    IF Pwok = 1 THEN DO
        Ok = Vrset( "HidePWbutton", "Enabled", 1)
        IF Showpw = 1 THEN DO
            Ok = Vrset( "HidePWbutton", "PicturePath", "#958:kricon.dll" )/* white spy */
        END
            ELSE DO
                Ok = Vrset( "HidePWbutton", "PicturePath", "#957:kricon.dll" )/* black spy */
            END
    END
        ELSE DO
            Ok = Vrset( "HidePWbutton", "Enabled", 0)
            Ok = Vrset( "HidePWbutton", "PicturePath", "#945:kricon.dll" )/* gray spy */
        END
RETURN

/*:VRX         DDEC_1_Notify
*/
Ddec_1_notify:
    SAY "hello from notify routine"
    SAY Vrinfo( "Item" )
    SAY Vrinfo( "Value" )
RETURN

/*:VRX         DDEMsg_Trigger
*/
DDEMsg_Trigger: 
    Value = KRFN3(21)
    Value = KRFN4()
return

/*:VRX         DescSort_Click
*/
DescSort_Click: 
    selected = VRGet( "DataNB", "Selected" )
    Ok = Vrsetini( Appname, "SORT" || Selected, 1, Ininame )
    CALL Sortarrange(Selected)
return

/*:VRX         DisposeRecord
*/
DisposeRecord: 
    parse arg Source, RecHandle

    Contindx = Vrget( "DataNB", "Selected" )
    
    /* get the current container name */
    Cont = Contnames.contindx || "Container" 

    Ok = Delrec(Vrwindow(), Vrget(Cont, "Self" ), RecHandle, Contindx, Appname, Ininame)
return Ok

/*:VRX         DoLogin
*/
Dologin:
    DO FOREVER
        OldPassword = Password
        Password = Login(Vrwindow(), Appname, Ininame, ARG(1), OldPassword)
        IF Password = "" THEN DO
            /* just shut down now */
            Buttons.1 = Vlsmsg(80)                              /* Ok */
            Buttons.0 = 1
            Id = Vrmessage( Vrwindow(), Vlsmsg(108) /* User cancel or blank password */, Vlsmsg(109) /* Shutting down */, "Information", "Buttons.", , )

            Window = Vrwindow()
            CALL Vrset Window, "Shutdown", 1
            DROP Window
            RETURN
        END
        IF Checkfileandpw() = 1 THEN DO
            Ok = Vrset("MainWin", "caption", "KeyRing/2    " || Vrgetini(Appname, "DB", Ininame))
            LEAVE
        END
    END
RETURN

/*:VRX         DragDiscard
*/
DragDiscard: 
    sourceobject = VRInfo( "SourceObject" )
    sourcerecord = VRInfo( "SourceRecord" )
    Ok = DisposeRecord(sourceobject, sourcerecord)
    IF Ok = 1 THEN DO
        Ok = Vrmethod( SourceObject, "RemoveRecord", SourceRecord)
        DirtyFlag = 1
    END
    DROP Ok

return

/*:VRX         EditItem
*/
Edititem: PROCEDURE EXPOSE Contnames. Appname Ininame DirtyFlag
    Contindx = Vrget( "DataNB", "Selected" )
    Cont = Contnames.contindx || "Container"/* get the current container name */

    /* get selected item(s) and edit them in-turn */
    /* zzzz Ok = Vrmethod( Cont, "GetRecordList", "SourceOrSelected", Selectedrecs. ) */
    Ok = Vrmethod( Cont, "GetRecordList", "Selected", Selectedrecs. )
    IF Selectedrecs.0 > 0 THEN DO
        DirtyFlag = 1
        DO Indx = 1 TO Selectedrecs.0
            Ok = Editrec(Vrwindow(), Vrget(Cont, "Self" ), Selectedrecs.indx, Contindx, Appname, Ininame)
        END
    END
        ELSE DO
            Buttons.1 = Vlsmsg(80)                              /* Ok */
            Buttons.0 = 1
            Id = Vrmessage( Vrwindow(), Vlsmsg(110) /* You must first select one or more items. */, Vlsmsg(111) /* Information */, "Information", "Buttons.", , )
            DROP Selectedrecs Id Buttons
        END
RETURN

/*:VRX         ExportItem_Click
*/
Exportitem_click:
    CALL Updatedbfromcontainers
    CALL Killhat
    
    Fn = Vrfiledialog(Vrwindow(), Vlsmsg(112) /* Save KeyRing/2 *un*encrypted database */, "Save", "*.PWC", , ,)
    IF Fn <> "" THEN DO
        CALL Launchhat
        Generations = Vrgetini( Appname, "BackupGenerationSpinner", Ininame )
        IF Generations = "" THEN
            Generations = 0

        Ok = Krsaveini(Fn, Password, 0, Generations)
        CALL Killhat
        DROP Ok
    END
    DROP Fn
RETURN

/*:VRX         FileSaveAsItem1_Click
*/
Filesaveasitem1_click:
    CALL Filesaveasitem_click
RETURN

/*:VRX         FileSaveAsItem_Click
*/
Filesaveasitem_click:
    CALL Dologin("Save As")
    CALL Updatedbfromcontainers
    CALL Killhat

RETURN

/*:VRX         Fini
*/
Fini:
    Window = Vrwindow()
    CALL Vrset Window, "Visible", 0
    DROP Window
    call krdropfuncs
RETURN 0

/*:VRX         FlushQueue
*/
Flushqueue:PROCEDURE
    DO WHILE Event<>"nop"
        Event=Vrevent("N")
    END
    DROP Event
RETURN

/*:VRX         FontPallette_Click
*/
Fontpallette_click:
    Font = Vrfontdialog(Vrwindow() "8.Helv", , Vlsmsg(253) /* Choose a font */)
    IF Font <> "" THEN DO
        Ok = Vrset( "AppContainer", "Font", Font )
        Ok = Vrset( "ComboContainer", "Font", Font )
        Ok = Vrset( "Other1Container", "Font", Font )
        Ok = Vrset( "Other2Container", "Font", Font )
        Ok = Vrset( "PINContainer", "Font", Font )
        Ok = Vrset( "WWWContainer", "Font", Font )
    END
RETURN

/*:VRX         GeneralHelpItem1_Click
*/
Generalhelpitem1_click:
    CALL Infhelp(Vrinfo("Source"))
RETURN

/*:VRX         GeneralHelpItem_Click
*/
Generalhelpitem_click:

RETURN

/*:VRX         GetColCount
*/
GetColCount: 
    /* return the number of enabled columns for this page */
    Pg = ARG(1)
    Count = 0
    do col = 1 to 9
        ColStr = KRGetColumnEnable(Pg, Col)
        parse var colstr enb "þ" flag "þ" hint
        if enb = 1 then do
            Count = Count + 1
        end
    end
    drop colstr enb flag hint pg col
return count

/*:VRX         GetDefaultAbbrev
*/
GetDefaultAbbrev:
    X = ARG(1) 

    select
    when X = 1 then do /* icon */
        return VLSMsg(99)
    end
    when X = 2 then do /* desc */
        return VLSMsg(235)
    end
    when X = 3 then do /* user */
        return VLSMsg(237)
    end
    when X = 4 then do /* pw */
        return VLSMsg(239)
    end
    when X = 5 then do /* s/n */
        return VLSMsg(103)
    end
    when X = 6 then do /* last upd */
        return VLSMsg(236)
    end
    otherwise do
        return ""
    end
    end

return

/*:VRX         GetDefaultHintText
*/
GetDefaultHintText: 
    Indx = ARG(1)
    SELECT
        WHEN Indx = 1 THEN DO
            RETURN Vlsmsg(157)/* Drop an icon here, or right click for options */
        END
        WHEN Indx = 2 THEN DO
            RETURN Vlsmsg(142)     /* Description of this secret info */
        END
        WHEN Indx = 3 THEN DO
            RETURN Vlsmsg(144)   /* Your name, alias, login name, Etc */
        END
        WHEN Indx = 4 THEN DO
            RETURN Vlsmsg(148)/* Password for this application, web page, login, Etc. */
        END
        WHEN Indx = 5 THEN DO
            RETURN Vlsmsg(146)/* Serial number, combination, PIN number, Etc for this secret */
        END
        WHEN Indx = 6 THEN DO
            RETURN ""                                 /* <lastupdate> */
        END
        WHEN Indx = 7 THEN DO
            RETURN Vlsmsg(154)/* Days to password expiration (warning only) */
        END
        WHEN Indx = 8 THEN DO
            RETURN Vlsmsg(151)                 /* URL for this secret */
        END
        WHEN Indx = 9 THEN DO
            RETURN Vlsmsg(152)                /* Note for this secret */
        END
        OTHERWISE DO
            RETURN "YYYY"                  /* <should never get here> */
        END
    END

return

/*:VRX         GetFieldIndex
*/
Getfieldindex: PROCEDURE
    /* look up field index for this page and flag */
    Pg = ARG(1)
    Flag = ARG(2)

    DO I = 1 TO 9
        Strg = Krgetcolumnenable(Pg, I)
        PARSE VAR Strg Tenb "þ" Tflag "þ" Thint
        IF Tflag = Flag THEN DO
            RETURN I
        END
    END

RETURN 0

/*:VRX         GetFieldStatus
*/
Getfieldstatus: PROCEDURE EXPOSE Contnames.
    /* look up field index for this page and flag */
    Pg = ARG(1)
    Flag = ARG(2)

    DO I = 1 TO 9
        Strg = Krgetcolumnenable(Pg, I)
        PARSE VAR Strg Tenb "þ" Tflag "þ" Thint
        IF Tflag = Flag THEN DO
            RETURN Tenb
        END
    END
RETURN 0
/*:VRX         GetFieldVal
*/
GetFieldVal: 
    GfPg = ARG(1)
    GfFlag = ARG(2)
    GfRec = ARG(3)
    GFSourceCont = Contnames.GfPg || "Container"
    Ok  = VRMethod(GFSourceCont , "GetFieldList", "GFFields." )
    Gfi = GetFieldIndex(GfPg, GfFlag)

    Retval = Vrmethod(GFSourceCont, "GetFieldData", GfRec, GFFields.Gfi)
    DROP GfPage GfFlag GfRec GFSourceCont Gfi
return RetVal

/*:VRX         GetPageHint
*/
Getpagehint:
    Value = Krgetpagehint(ARG(2))
    IF Value = "" THEN DO
        Value = Vlsmsg(ARG(1))
    END
RETURN Value

/*:VRX         GetSingleSelItem
*/
Getsingleselitem:
    Cont = ARG(1)
    Ok = Vrmethod( Cont||"Container", "GetRecordList", "Selected", "SelectedRecs." )
    IF Selectedrecs.0 = 0 THEN DO
        Buttons.1 = Vlsmsg(80)                                  /* Ok */
        Buttons.0 = 1
        Id = Vrmessage( Vrwindow(), Vlsmsg(113) /* No items selected */, Vlsmsg(82) /* Info */, "Information", "Buttons.", , )
        DROP Cont Buttons Selectedrecs
        RETURN ""
    END
    Buttons.1 = Vlsmsg(83)                                     /* Yes */
    Buttons.2 = Vlsmsg(84)                                      /* No */
    Buttons.0 = 2
    IF Selectedrecs.0 = 1 THEN DO
        RETURN Selectedrecs.1
    END
        ELSE DO
            Buttons.1 = Vlsmsg(80)                              /* Ok */
            Buttons.0 = 1
            Id = Vrmessage( Vrwindow(), Vlsmsg(114) /* More than one item selected */, Vlsmsg(82) /* Info */, "Information", "Buttons.", , )
            DROP Selectedrecs Cont Buttons
            RETURN ""
        END
RETURN

/*:VRX         GetTickLabel
*/
GetTickLabel: 
    Page = ARG(1)
    Flag = ARG(2)
    DO I = 1 TO 9
        Colstr = Krgetcolumnenable(Page, I)
        PARSE VAR Colstr E "þ" F "þ" H "þ" A
        IF Flag = F THEN DO
            RETURN A
        END
    END
return

/*:VRX         GetTopicIndex
*/
Gettopicindex:
    App = TRANSLATE(ARG(1))
    Topicname = TRANSLATE(ARG(2))

    Topics.0 = 0
    Ok = Vrmethod( "DDEC_1", "Initiate", "Topics.")
    IF Ok <> 1 THEN DO
        Buttons.1 = Vlsmsg(80)                                  /* Ok */
        Buttons.0 = 1
        Id = Vrmessage( Vrwindow(), Vlsmsg(115) /* Communications with  */|| App || Vlsmsg(116) /*  failed! */, Vlsmsg(93) /* Error */, "Error", "Buttons.", , )
        RETURN 0
    END
    DO I = 1 TO Topics.0
        Topics.i = TRANSLATE( Topics.i )
        PARSE VAR Topics.i Thisapp "," Thistopic
        IF App = Thisapp THEN DO
            IF Topicname = Thistopic THEN DO
                DROP Topics App Thisapp Thistopic Topicname Ok
                RETURN I
            END
        END
    END
RETURN 0

/*:VRX         GetTxtHyt
*/
Gettxthyt: PROCEDURE
    Componentname = ARG(1)

    Font = Vrget( Componentname, "Font" )
    Ok = Vrset( "DummyDT", "Font", Font )
    Ok = Vrset( "DummyDT", "Caption", "XXX")
RETURN Vrget( "DummyDT", "Height" )

/*:VRX         GetTxtWidth
*/
Gettxtwidth: PROCEDURE
    Componentname = ARG(1)
    Strg = ARG(2)

    Font = Vrget( Componentname, "Font" )
    Ok = Vrset( "DummyDT", "Font", Font )
    Ok = Vrset( "DummyDT", "Caption", Strg)
RETURN Vrget( "DummyDT", "Width" )

/*:VRX         Halt
*/
Halt:
    SIGNAL _vrehalt
RETURN

/*:VRX         HatReady
*/
Hatready:
    Hatisready = 1
RETURN

/*:VRX         HelpButton_Click
*/
Helpbutton_click:
    CALL Infhelp(Vrinfo("Source"))
RETURN

/*:VRX         HelpIndexItem1_Click
*/
Helpindexitem1_click:
    CALL Infhelp(Vrinfo("Source"))
RETURN

/*:VRX         HidePWbutton_Click
*/
Hidepwbutton_click:
    IF Iniloaded = 1 THEN DO
        IF Showpw <> 1 THEN DO
            Ok = Vrset( "HidePWbutton", "PicturePath", "#958:kricon.dll" )/* white spy */
            Ok = Vrset( "HidePWbutton", "HintText", Vlsmsg(117) /* Hide Password Column */ )
            Showpw = 1
        END
            ELSE DO
                Ok = Vrset( "HidePWbutton", "PicturePath", "#957:kricon.dll" )/* black spy */
                Ok = Vrset( "HidePWbutton", "HintText", Vlsmsg(118) /* Show Password Column */ )
                Showpw = 0
            END
        Ok = Hideshowpw()
    END
    Ok = Vrsetini( Appname, "SHOWPW", Showpw, Ininame )
RETURN

/*:VRX         HideShowPW
*/
Hideshowpw:
    DO I = 1 TO Contnames.0 - 1
        IF Getfieldstatus(I, "P") = 1 THEN DO
            Ok = Vrmethod( Contnames.i || "Container", "SetFieldAttr", Getfieldname(I, "P"), "Visible", Showpw )
        END
    END
RETURN Ok

/*:VRX         IconSort_Click
*/
IconSort_Click: 
    selected = VRGet( "DataNB", "Selected" )
    Ok = Vrsetini( Appname, "SORT" || Selected, 6, Ininame )
    CALL Sortarrange(Selected)
return

/*:VRX         Import
*/
Import: 
    CALL Launchhat
    Ok = Krimport(Filename, Password)
    SELECT
        WHEN Ok = 0 THEN DO
            /* should never get here*/
        END
        WHEN Ok = 1 THEN DO
            /* Success */
            Oldfilename = Filename
            Iniloaded = 1
        END
        WHEN Ok = 99 THEN DO
            CALL Killhat
            /* Expired */
            Buttons.1 = Vlsmsg(95)                      /* Byebye */
            Buttons.0 = 1
            Id = Vrmessage( Vrwindow(), Vlsmsg(96) /* Product Expired! */, Vlsmsg(97) /* Errorrrrr! */, "Error", "Buttons.", , )
            Iniloaded = 0
        END
        OTHERWISE DO                                       /* 200 */
            CALL Killhat
            Iniloaded = 0
            Buttons.1 = Vlsmsg(80)                          /* Ok */
            Buttons.0 = 1
            Id = Vrmessage( Vrwindow(), Vlsmsg(98) /* Invalid Password */, Vlsmsg(79) /* Error! */, "Error", "Buttons.", , )
            DROP Prompt Buttons Id
        END
    END
    CALL Killhat
    IF Iniloaded = 1 THEN DO
        Ok = Vrsetini( Appname, "DB", Vrparsefilename( Filename, "DPN" ) || ".PWX", Ininame )
        DO FOREVER
            CALL Dologin("Save As")
            IF Vrfileexists( Vrgetini(Appname, "DB", Ininame )) = 1 THEN DO
                Buttons.1 = Vlsmsg(255)              /* Overwrite */
                Buttons.2 = Vlsmsg(256)              /* Try Again */
                Buttons.0 = 2
                Id = Vrmessage( Vrwindow(), Vrgetini(Appname, "DB", Ininame ) || Vlsmsg(257) /*  exists - it will be overwritten! */, Vlsmsg(258) /* File Overwrite Warning */, "Warning", "Buttons.", 1, 2 )
                IF Id = 1 THEN DO
                    LEAVE
                END
            END
            ELSE DO
                LEAVE
            END
        END
    END

    CALL Updatecontainersfromtree
    Ok = Vrset("MainWin", "Caption", "KeyRing/2    " || Vrgetini(Appname, "DB", Ininame))
    CALL Killhat

return

/*:VRX         ImportItem_Click
*/
Importitem_click:
    /* first save the current file, if any */
    CALL Updatedbfromcontainers
    CALL Killhat
    /* unload the tree from memory */
    /* CALL Krdisposeini */
    CALL Normalmouse

    /* kill the hat thread, if any */
    IF Threadid <> -1 THEN DO
        Ok = Vrmethod( "Application", "HaltThread", Threadid )
        Threadid = -1
    END

    /* now open or create a new file */
    Iniloaded = 0

    Filename = Vrfiledialog( Vrwindow(), Vlsmsg(254) /* Please select a clear text import file */, "Open", "*.PWC", , , )
    IF Filename <> "" THEN DO
        call import
    end
RETURN

/*:VRX         INFHelp
*/
Infhelp:
    IF ARG(1) <> "" THEN DO
        ADDRESS Cmd 'start view kr2.inf' Vrget(ARG(1), "UserData")
    END
        ELSE DO
            ADDRESS Cmd 'start view kr2.inf'
        END
RETURN 1

/*:VRX         Init
*/
Init:
    Ok = RXFUNCADD("VLLoadFuncs", "VLMSG", "VLLoadFuncs")/* do not modify or move this line! It must be on line #2 of this function */
    CALL Vlloadfuncs/* do not modify or move this line! It must be on line #3 of this function */

    Ok = Vrredirectstdio("On", "keyring2.err")

    Ok = RXFUNCADD("KRILoadFuncs", "KRINI", "KRILoadFuncs")
    Ok= Kriloadfuncs()

    Ok = RXFUNCADD("KRICLoadFuncs", "KRICON", "KRICLoadFuncs")
    CALL Kricloadfuncs

    Ok = RXFUNCADD("KRRLoadFuncs", "KREGISTR", "KRRLoadFuncs")
    CALL Krrloadfuncs

    Appname = "KR2"
    Ininame = "KR2.INI"

    Langname = Vrgetini( Appname, "LANGUAGE", Ininame, "NOCLOSE" )
    IF Langname = "" THEN DO
        Langname = "ENGLISH.MSG"
    END
    Ok = Vlopenlang(Langname, Langname)

    CALL Waitmouse
    CALL Mainwin_langinit
    Lasttime = 30
    Threadid = -1
    Hatisready = 0
    Forceresize = 0
    Ttcolor = 0

    /* Sort slider field map */
    Tickmap.1 = "D"                                           /* desc */
    Tickmap.2 = "L"                                            /* upd */
    Tickmap.3 = "N"                                           /* user */
    Tickmap.4 = "S"                                             /* sn */
    Tickmap.5 = "P"                                             /* pw */
    Tickmap.6 = "I"                                            /* ico */
    TickMap.0 = 6

    /* NB page prefixes for containers */
    Contnames.1 = "WWW"
    Contnames.2 = "App"
    Contnames.3 = "PIN"
    Contnames.4 = "Combo"
    Contnames.5 = "Other1"
    Contnames.6 = "Other2"
    Contnames.7 = "Boss"
    Contnames.0 = 7

    Pglogo.1 = "$ 135:kricon.dll"
    Pglogo.2 = "$ 18:kricon.dll"
    Pglogo.3 = "$ 36:kricon.dll"
    Pglogo.4 = "$ 38:kricon.dll"
    Pglogo.5 = "$ 83:kricon.dll"
    Pglogo.6 = "$ 2:kricon.dll"

    Iniloaded = 0
    Initstat = Init2()
    Window = Vrwindow()

    Height = Vrgetini( Appname, "MainHeight", Ininame, "NoClose" )
    IF Height <> "" THEN do
        Ok = Vrset("MainWin", "Height", Height)
    end

    Width = Vrgetini( Appname, "MainWidth", Ininame, "NoClose" )
    IF Width <> "" THEN do
        Ok = Vrset("MainWin", "Width", Width)
    end

    Top = Vrgetini( Appname, "MainTop", Ininame, "NoClose" )
    IF Top <> "" THEN do 
        Ok = Vrset("MainWin", "Top", Top)
    end

    Left = Vrgetini( Appname, "MainLeft", Ininame, "NoClose" )
    IF Left <> "" THEN do
        Ok = Vrset("MainWin", "Left", Left)
    end

    Newitemthreadid = -1

    Oldfilename = "uninit"
    Oldpassword = ""
    Showpw = Vrgetini( Appname, "SHOWPW", Ininame)
    IF Showpw = "" THEN DO
        Showpw = 0
    END

    IF Showpw = 1 THEN DO
        Ok = Vrset( "HidePWbutton", "PicturePath", "#958:kricon.dll" )
        Ok = Vrset( "HidePWbutton", "HintText", Vlsmsg(117) /* Hide Password Column */ )
    END
    ELSE DO
            Ok = Vrset( "HidePWbutton", "PicturePath", "#957:kricon.dll" )
            Ok = Vrset( "HidePWbutton", "HintText", Vlsmsg(118) /* Show Password Column */ )
    END
    CALL Normalmouse

    Appname = "KR2"
    Ininame = "KR2.INI"

    Value = Vrgetini( "KR2", "SoundEnable", "KR2.INI")
    IF Value = "" then
        Value = 1
    Ok = VRSetIni(AppName, "SoundEnable", Value, IniName)
    IF Value = 1 THEN DO
        Value = Vrgetini( "KR2", "SoundFile", "KR2.INI")
        IF Value = "" then do
            Value = "intro.mid"
            Ok = VRSetIni(AppName, "SoundFile", Value, IniName)
        end
        Ok= KRPlayIntro(Value)
    end

    Value = VRGet("Application", "CommandLine")
    if Value <> "" THEN
        Ok = VrSetini( Appname, "DB", Value, Ininame)

    CALL Dologin

    if Vrgetini( Appname, "SoundEnable", Ininame) = 1 then do
        Ok=KRKillIntro()
    end

    Window = Vrwindow()
    IF Password <> "" THEN DO
        CALL Reinitpages
        CALL Restoreprops
        CALL Settabs
        Ok = Vrset( "DataNB", "Visible", 0 )
        CALL Vrset Vrwindow(), "Visible", 1
        CALL Vrmethod Window, "Activate"
        Sp = Vrgetini( Appname, "StickyPage", Ininame)
        IF Sp > 0 THEN
            Ok = VRSet( "DataNB", "Selected", Sp )
        CALL Vrset Vrwindow(), "Visible", 1
        DROP Window Ok Sp
    END
RETURN
/*:VRX         Init2
*/
Init2:
    call normalmouse
    Ok = KRFN3(1)
    IF Ok = 0 THEN DO
        Ok = Nagger(VRWindow(), Appname, IniName, 0)
    end
    else do
        if KRFN10(2) <> 1 then do
            Ok = Nagger(VRWindow(), Appname, IniName, 1)
        end
    end
    DirtyFlag = 0
RETURN 0

/*:VRX         Keyring2HelpItem1_Click
*/
Keyring2helpitem1_click:
    CALL Infhelp(Vrinfo("Source"))
RETURN

/*:VRX         KeysHelpItem1_Click
*/
Keyshelpitem1_click:
    CALL Infhelp(Vrinfo("Source"))

RETURN

/*:VRX         KillHat
*/
Killhat:
    /* tell hat to commit suicide */
    IF Threadid <> -1 THEN DO
        CALL Vrmethod "Application", "PostQueue", Threadid, 1, "Call Quit"
        Threadid = -1/* flag thread as done, even though it might take a while */
    END

    CALL Normalmouse
RETURN

/*:VRX         KillTimer_Click
*/
Killtimer_click:
    Ok = Vrset( "BrowserTimer", "Enabled", 0 )
    Ok = Vrset( "BrowserTimer", "Visible", 0)
RETURN

/*:VRX         LangChanged
*/
Langchanged:
    Ok=Vrset("DataNB", "Visible", 0)
    CALL Mainwin_langinit
    CALL Appwin_langinit
    CALL Combowin_langinit
    CALL Other1win_langinit
    CALL Other2win_langinit
    CALL Pinwin_langinit
    CALL Wwwwin_langinit
    CALL Containers_langinit
    CALL Reinitpages
    CALL Mainwin_resize
    Ok=Vrset("DataNB", "Visible", 1)
RETURN

/*:VRX         LaunchHat
*/
Launchhat:
    CALL Waitmouse
    IF Threadid = -1 THEN DO
        Threadid = Vrmethod( "Application", "StartThread", "Working", Vrwindow(), Appname, Ininame, Langname )
    END
RETURN

/*:VRX         MainWin_Close
*/
Mainwin_close:
    CALL Quit
RETURN

/*:VRX         MainWin_Help
*/
Mainwin_help:
    CALL Infhelp(Vrinfo("Source"))
RETURN



/*:VRX         MainWin_LangException
*/
MainWin_LangException: 

return

/*:VRX         MainWin_LangInit
*/
MainWin_LangInit:

    /* ------------------------------------------------ */
    /* Language internationalization code autogenerated */
    /* by VXNation v1.0, Copyright 1999, IDK, Inc.      */
    /*          http://www.idk-inc.com                  */
    /* Autogenerated: 03/06/2000 19:08:42             */
    /* ------------------------------------------------ */
    /* Warning! This code gets overwritten by VXNation! */
    /* Do not make modifications here!                  */
    /* ------------------------------------------------ */

    /* KeyRing/2 */
    Ok = VRSet("MainWin", "WindowListTitle", VLSMsg(2))

    /* KeyRing/2 */
    Ok = VRSet("MainWin", "Caption", VLSMsg(2))

    /* Get help on KeyRing/2 */
    Ok = VRSet("HelpButton", "HintText", VLSMsg(4))

    /* Close KeyRing/2 */
    Ok = VRSet("QuitButton", "HintText", VLSMsg(5))

    /* Hide password column */
    Ok = VRSet("HidePWbutton", "HintText", VLSMsg(6))

    /* Open browser on current URL entry */
    Ok = VRSet("BrowserButton", "HintText", VLSMsg(7))

    /* Change KeyRing/2 Settings */
    Ok = VRSet("SetupButton", "HintText", VLSMsg(8))

    /* Open/Create password database */
    Ok = VRSet("NewButton", "HintText", VLSMsg(9))

    /* 45 */
    Ok = VRSet("BrowserTimer", "Caption", VLSMsg(10))

    /* No conversation active. */
    Ok = VRSet("DDEC_1", "Caption", VLSMsg(11))

    /* Save database changes */
    Ok = VRSet("SaveButton", "HintText", VLSMsg(3))

    /* Check database for expired passwords */
    Ok = VRSet("CheckExpiredButton", "HintText", VLSMsg(44))

    /* Timer */
    Ok = VRSet("DDEMsg", "Caption", VLSMsg(66))

    /* ~File */
    Ok = VRSet("FileItem1", "Caption", VLSMsg(12))

    /* ~Open */
    Ok = VRSet("NewFile", "Caption", VLSMsg(13))

    /* Open a new password database */
    Ok = VRSet("NewFile", "HintText", VLSMsg(14))

    /* ~Save */
    Ok = VRSet("UpdateDBFromContainers", "Caption", VLSMsg(15))

    /* Save the current database */
    Ok = VRSet("UpdateDBFromContainers", "HintText", VLSMsg(16))

    /* Save ~As */
    Ok = VRSet("FileSaveAsItem1", "Caption", VLSMsg(17))

    /* Save the current database under a new name */
    Ok = VRSet("FileSaveAsItem1", "HintText", VLSMsg(18))

    /* Se~tup */
    Ok = VRSet("SetupItem", "Caption", VLSMsg(19))

    /* Change Settings of KeyRing/2 */
    Ok = VRSet("SetupItem", "HintText", VLSMsg(389))

    /* ~Export */
    Ok = VRSet("ExportItem", "Caption", VLSMsg(21))

    /* Save the database as an unencrypted text file */
    Ok = VRSet("ExportItem", "HintText", VLSMsg(20))

    /* ~Import */
    Ok = VRSet("ImportItem", "Caption", VLSMsg(248))

    /* Save the database as an unencrypted text file */
    Ok = VRSet("ImportItem", "HintText", VLSMsg(388))

    /* ~Print */
    Ok = VRSet("PrintItem", "Caption", VLSMsg(22))

    /* print all database entries and passwords */
    Ok = VRSet("PrintItem", "HintText", VLSMsg(23))

    /* - */
    Ok = VRSet("MItem_9", "Caption", VLSMsg(24))

    /* ~Language Change */
    Ok = VRSet("ChangeLang", "Caption", VLSMsg(249))

    /* ~Font Palette */
    Ok = VRSet("FontPallette", "Caption", VLSMsg(250))

    /* - */
    Ok = VRSet("MItem_8", "Caption", VLSMsg(24))

    /* E~xit */
    Ok = VRSet("Quit1", "Caption", VLSMsg(25))

    /* Quit KeyRing/2 */
    Ok = VRSet("Quit1", "HintText", VLSMsg(26))

    /* ~Help */
    Ok = VRSet("HelpItem1", "Caption", VLSMsg(27))

    /* Help ~Index */
    Ok = VRSet("HelpIndexItem1", "Caption", VLSMsg(28))

    /* View table of contents on KeyRing/2 topics */
    Ok = VRSet("HelpIndexItem1", "HintText", VLSMsg(29))

    /* ~General Help */
    Ok = VRSet("GeneralHelpItem1", "Caption", VLSMsg(30))

    /* View help on general OS/2 application topics */
    Ok = VRSet("GeneralHelpItem1", "HintText", VLSMsg(31))

    /* ~Using Help */
    Ok = VRSet("UsingHelpItem1", "Caption", VLSMsg(32))

    /* View information on how to use the help system */
    Ok = VRSet("UsingHelpItem1", "HintText", VLSMsg(33))

    /* ~Keys help */
    Ok = VRSet("KeysHelpItem1", "Caption", VLSMsg(34))

    /* View help on hotkeys and mouse actions */
    Ok = VRSet("KeysHelpItem1", "HintText", VLSMsg(35))

    /* - */
    Ok = VRSet("MItem_16", "Caption", VLSMsg(24))

    /* Key~ring2 Help */
    Ok = VRSet("Keyring2HelpItem1", "Caption", VLSMsg(36))

    /* View KeyRing/2 general help */
    Ok = VRSet("Keyring2HelpItem1", "HintText", VLSMsg(37))

    /* - */
    Ok = VRSet("MItem_18", "Caption", VLSMsg(24))

    /* ~Product Information */
    Ok = VRSet("ProductInfoItem1", "Caption", VLSMsg(38))

    /* View product version and registration */
    Ok = VRSet("ProductInfoItem1", "HintText", VLSMsg(39))

    /* TimerMenu */
    Ok = VRSet("TimerMenu", "Caption", VLSMsg(40))

    /* Kill Timer */
    Ok = VRSet("KillTimer", "Caption", VLSMsg(41))

    /* IconMenu */
    Ok = VRSet("IconMenu", "Caption", VLSMsg(167))

    /* Open Icon ~File */
    Ok = VRSet("OpenIconFile", "Caption", VLSMsg(65))

    /* Select ~Internal Icon */
    Ok = VRSet("SelInternalLogoIcon", "Caption", VLSMsg(69))

    call MainWin_LangException
    DROP Ok

RETURN

/*:VRX         MainWin_Resize
*/
Mainwin_resize:
    call wwwwin_resize
    call appwin_resize
    call combowin_resize
    call other1win_resize
    call other2win_resize
    call pinwin_resize

    Height = Vrget( "MainWin", "Height" )
    Width = Vrget( "MainWin", "Width" )

    IF Height = Lastmainheight THEN DO
        IF Width = Lastmainwidth THEN DO
            RETURN
        END
    END
    Ok = Vrset("datanb", "visible", 0)
    Lastmainheight = Height
    Lastmainwidth = Width
    Ok = Vrset( "BottomRedLine", "Width", Width - 50 )
   
    Ok = Vrset( "TopRedLine", "Width", Width - 50 )
    Ok = Vrset( "GradientBar", "Width", Width - 50 )
    Ok = Vrset( "DataNB", "Height", Height - 1700 )
    Ok = Vrset( "DataNB", "Width", Width-100 )
    Ok = Vrset("datanb", "visible", 1)
RETURN

/*:VRX         MoveItemsToPage
*/
MoveItemsToPage: PROCEDURE EXPOSE Contnames. DirtyFlag 
    SourcePage = Vrget( "DataNB", "Selected" )
    DestPage = arg(1)

    SourceCont = Contnames.SourcePage || "Container" /* get the current container name */
    DestCont = Contnames.DestPage || "Container" /* get destination container name */

    ok = VRMethod( SourceCont, "GetFieldList", "SourceFields." )
    ok = VRMethod( DestCont, "GetFieldList", "DestFields." )

    /* get selected item(s) and move them in-turn */
    Ok = Vrmethod( SourceCont, "GetRecordList", "Selected", Selectedrecs. )

    SourceOrder = Getorder(SourcePage)
    DestOrder = GetOrder(DestPage)

    IF Selectedrecs.0 > 0 THEN DO
        DirtyFlag = 1
        DO Indx = 1 TO Selectedrecs.0
            /* get the stuff we need to create the initial icon */
            Icon = GetFieldVal(SourcePage, "I", SelectedRecs.Indx)
            Caption = GetFieldVal(SourcePage, "D", SelectedRecs.Indx)

            /* create new record in destination container */
            recordHandle = VRMethod( DestCont, "AddRecord", , "Last", Caption, Icon, ,  )

            /* set column order field */
            Ok = Vrmethod( DestCont, "SetFieldData", Recordhandle, DestFields.10, DestOrder)

            /* copy all the fields over */
            Ok = SetFieldVal(DestPage, recordHandle, "I", GetFieldVal(SourcePage, "I", SelectedRecs.Indx))
            Ok = SetFieldVal(DestPage, recordHandle, "D", GetFieldVal(SourcePage, "D", SelectedRecs.Indx))
            Ok = SetFieldVal(DestPage, recordHandle, "N", GetFieldVal(SourcePage, "N", SelectedRecs.Indx))
            Ok = SetFieldVal(DestPage, recordHandle, "P", GetFieldVal(SourcePage, "P", SelectedRecs.Indx))
            Ok = SetFieldVal(DestPage, recordHandle, "S", GetFieldVal(SourcePage, "S", SelectedRecs.Indx))
            Ok = SetFieldVal(DestPage, recordHandle, "L", GetFieldVal(SourcePage, "L", SelectedRecs.Indx))
            Ok = SetFieldVal(DestPage, recordHandle, "E", GetFieldVal(SourcePage, "E", SelectedRecs.Indx))
            Ok = SetFieldVal(DestPage, recordHandle, "U", GetFieldVal(SourcePage, "U", SelectedRecs.Indx))
            Ok = SetFieldVal(DestPage, recordHandle, "W", GetFieldVal(SourcePage, "W", SelectedRecs.Indx))

            /* delete the old record from the source container */
            ok = VRMethod( SourceCont, "RemoveRecord", Selectedrecs.indx )
            DirtyFlag = 1
        END
    END
        ELSE DO
            Buttons.1 = Vlsmsg(80)                              /* Ok */
            Buttons.0 = 1
            Id = Vrmessage( Vrwindow(), Vlsmsg(110) /* You must first select one or more items. */, Vlsmsg(111) /* Information */, "Information", "Buttons.", , )
            DROP Selectedrecs Id Buttons
        END
RETURN 1
/*:VRX         MoveToPg1_Click
*/
MoveToPg1_Click: 
    Ok = MoveItemsToPage(1)
return

/*:VRX         MoveToPg2_Click
*/
MoveToPg2_Click: 
    Ok = MoveItemsToPage(2)

return

/*:VRX         MoveToPg3_Click
*/
MoveToPg3_Click: 
    Ok = MoveItemsToPage(3)

return

/*:VRX         MoveToPg4_Click
*/
MoveToPg4_Click: 
    Ok = MoveItemsToPage(4)

return

/*:VRX         MoveToPg5_Click
*/
MoveToPg5_Click: 
    Ok = MoveItemsToPage(5)

return

/*:VRX         MoveToPg6_Click
*/
MoveToPg6_Click: 
    Ok = MoveItemsToPage(6)

return

/*:VRX         NameToClip_Click
*/
NameToClip_Click: 
    Ok = Vrmethod( Vrinfo("Source"), "GetRecordList", "SourceOrSelected", "SelectedRecs." )
    IF Selectedrecs.0 > 1 THEN DO
        Buttons.1 = Vlsmsg(80)                                  /* Ok */
        Buttons.0 = 1
        Id = Vrmessage( Vrwindow(), Vlsmsg(119) /* More than one item is selected */, Vlsmsg(120) /* Warning! */, "Warning", "Buttons.", , )
        RETURN
    END
    IF Selectedrecs.0 = 0 THEN DO
        Buttons.1 = Vlsmsg(80)                                  /* Ok */
        Buttons.0 = 1
        Id = Vrmessage( Vrwindow(), Vlsmsg(121) /* No item was selected */, Vlsmsg(120) /* Warning! */, "Warning", "Buttons.", , )
        RETURN
    END
    Value = Vrmethod(Vrinfo("Source"), "GetFieldData", SelectedRecs.1, Fieldvals. )
    Indx = GetFieldIndex(VRGet("DataNB", "Selected"), "N")
    Ok = Vrmethod("Application", "PutClipBoard", Fieldvals.Indx)

return

/*:VRX         NewButton_Click
*/
Newbutton_click:
    CALL Newfile_click
RETURN

/*:VRX         NewFile_Click
*/
Newfile_click:
    /* first save the current file, if any */
    CALL Updatedbfromcontainers
    CALL Killhat

    /* unload the tree from memory */
    CALL Krdisposeini

    CALL Normalmouse

    /* now open or create a new file */
    IF Threadid <> -1 THEN DO
        Ok = Vrmethod( "Application", "HaltThread", Threadid )
        Threadid = -1
    END

    Iniloaded = 0

    CALL Dologin

    IF Iniloaded THEN DO
        /* CALL Updatecontainersfromtree */
        CALL Reinitpages
        CALL Restoreprops
        CALL Settabs
        Ok = Vrset("MainWin", "Caption", "KeyRing/2    " || Vrgetini(Appname, "DB", Ininame))
    END

    CALL Killhat
RETURN

/*:VRX         OpenIconFile_Click
*/
Openiconfile_click:
    Filename = Vrfiledialog( Vrwindow(), Vlsmsg(170) /* Select an Icon for this secret */, "Open", Addbackslash(Vrgetini( Appname, "IconPath", Ininame )) || "*.ico", , , )
    IF Filename = "" THEN do
        Filename = "# 1"
    end

    Ok = Vrsetini( Appname, "IconPath", Vrparsefilepath(Filename, "DP" ), Ininame )
    SAY Filename
    SAY VRINFO("SOURCE")
    Ok = Vrset( Vrinfo("Source"), "PicturePath", Filename )

RETURN

/*:VRX         Other1Container_ContextMenu
*/
Other1container_contextmenu:
    CALL Vrmethod "AppEditMenu", "popup"
RETURN

/*:VRX         Other1Container_DoubleClick
*/
Other1container_doubleclick:
    CALL Edititem
RETURN

/*:VRX         Other1Container_DragDiscard
*/
Other1Container_DragDiscard: 
    CALL DragDiscard
return

/*:VRX         Other1Container_DragDrop
*/
Other1container_dragdrop:
    Record = Vrinfo( "Record" )
    Srcfile = Vrinfo( "SourceFile" )
    Container = Vrinfo("SourceObject")
    Targrec = Vrinfo("TargetRecord")

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
        Ok = Vrmethod( Vrinfo("TargetObject"), "SetFieldData", Targrec, Getfieldname(5, "I"), Value)
    END
        ELSE DO
            /* dropped on empty space */
            /* Create new record using the dropped icon */
            Ok = Addrec(5, Value)
        END

RETURN

/*:VRX         Other1DetailRB_Click
*/
Other1detailrb_click:
    /* zzzz enable sort menu */
    Ok = Vrsetini( Appname, "VIEW5", 2, Ininame )
    Ok = Sortarrange(5)
RETURN

/*:VRX         Other1IconRB_Click
*/
Other1iconrb_click:
    /* zzzz disable sort menu */
    Ok = Vrsetini( Appname, "VIEW5", 1, Ininame )
    Ok = Sortarrange(5)
RETURN

/*:VRX         Other1LargeIconRB_Click
*/
Other1largeiconrb_click:
    Ok = Vrset( "Other1Container", "MiniIcons", 0 )
    Ok = Vrsetini( Appname, "MINI5", 0, Ininame )
    CALL Sortarrange(5)
RETURN

/*:VRX         Other1NewButton_Click
*/
Other1newbutton_click:
    CALL Addrec(5)
RETURN

/*:VRX         Other1SmallIconRB_Click
*/
Other1smalliconrb_click:
    Ok = Vrset( "Other1Container", "MiniIcons", 1 )
    Ok = Vrsetini( Appname, "MINI5", 1, Ininame )
    CALL Sortarrange(5)
RETURN

/*:VRX         Other1Win_Close
*/
Other1win_close:
    CALL Saveprops
    CALL Other1win_fini
RETURN

/*:VRX         Other1Win_Create
*/
Other1win_create:
    CALL Other1win_init
RETURN

/*:VRX         Other1Win_Fini
*/
Other1win_fini:
    Window = Vrinfo( "Window" )
    CALL Vrdestroy Window
    DROP Window
RETURN
/*:VRX         Other1Win_Help
*/
Other1win_help:
    CALL Infhelp(Vrinfo("Source"))
RETURN

/*:VRX         Other1Win_Init
*/
Other1win_init:
    CALL Other1Win_LangInit /* do not modify or move this line! It must be on line #1 of this function */
    Window = Vrinfo( "Object" )
    /*
    IF( \Vrischildof( Window, "Notebook" ) ) THEN DO
        CALL Vrmethod Window, "CenterWindow"
        CALL Vrset Window, "Visible", 1
        CALL Vrmethod Window, "Activate"
    END
    */
    CALL Containerinit(5)
    CALL Container_langinit(5)
    CALL Restoreprops
    Other1wininited = 1
    DROP Window
RETURN



/*:VRX         Other1Win_LangException
*/
Other1Win_LangException: 
    call SetTickLabels(5) 
return

/*:VRX         Other1Win_LangInit
*/
Other1Win_LangInit:

    /* ------------------------------------------------ */
    /* Language internationalization code autogenerated */
    /* by VXNation v1.0, Copyright 1999, IDK, Inc.      */
    /*          http://www.idk-inc.com                  */
    /* Autogenerated: 03/06/2000 19:08:43             */
    /* ------------------------------------------------ */
    /* Warning! This code gets overwritten by VXNation! */
    /* Do not make modifications here!                  */
    /* ------------------------------------------------ */

    /* List of user specified secrets */
    Ok = VRSet("Other1Win", "HintText", VLSMsg(282))

    /* User Codes */
    Ok = VRSet("Other1Container", "Caption", VLSMsg(74))

    /* List of user specified secrets */
    Ok = VRSet("Other1Container", "HintText", VLSMsg(282))

    /* Timer */
    Ok = VRSet("Other1WinFlashTimer", "Caption", VLSMsg(66))

    /* ;Dsc;Upd;Usr;S/N;Pw;Icon */
    MyTick.1 = VLSMsg(235)
    MyTick.2 = VLSMsg(236)
    MyTick.3 = VLSMsg(237)
    MyTick.4 = VLSMsg(103)
    MyTick.5 = VLSMsg(239)
    MyTick.6 = VLSMsg(99)
    MyTick.0 = 6
/*
    Ok = VRMethod("Other1SortSlide", "SetTickLabels", "MyTick.")
    DROP MyTick.

    Ok = VRSet("Other1SortSlide", "HintText", VLSMsg(46))
*/
    /* ~Large Icons */
    Ok = VRSet("Other1LargeIconRB", "Caption", VLSMsg(47))

    /* Selects Large icon size */
    Ok = VRSet("Other1LargeIconRB", "HintText", VLSMsg(48))

    /* ~Small Icons */
    Ok = VRSet("Other1SmallIconRB", "Caption", VLSMsg(49))

    /* Selects Small icon size */
    Ok = VRSet("Other1SmallIconRB", "HintText", VLSMsg(72))

    /* ~Icon View */
    Ok = VRSet("Other1IconRB", "Caption", VLSMsg(50))

    /* Select icon view of application codes */
    Ok = VRSet("Other1IconRB", "HintText", VLSMsg(51))

    /* ~Detail View */
    Ok = VRSet("Other1DetailRB", "Caption", VLSMsg(52))

    /* Select details view of application codes */
    Ok = VRSet("Other1DetailRB", "HintText", VLSMsg(53))

    /* I'm a logo! */
    Ok = VRSet("Pg5Icon", "HintText", VLSMsg(156))

    /* ~New */
    Ok = VRSet("Other1NewButton", "Caption", VLSMsg(54))

    /* Click to create a new record */
    Ok = VRSet("Other1NewButton", "HintText", VLSMsg(75))

    call Other1Win_LangException
    DROP Ok

RETURN

/*:VRX         Other1Win_Resize
*/
Other1win_resize: PROCEDURE EXPOSE Lastheight Lastwidth
    IF Vrget( "DataNB", "Selected" ) <> 5 THEN DO
        RETURN
    END

    Ok = ContainerResize("Other1", 5)
RETURN

/*:VRX         Other1WinFlashTimer_Trigger
*/
Other1winflashtimer_trigger:
    Ok = Vrset("Other1Container", "Visible", 0)
    Ok = Vrmethod( "Other1Container", "SortRecords" )
    Ok = Vrmethod( "Other1Container", "Arrange" )

    CALL Other1win_langinit
    CALL Container_langinit(5)
    Ok = Vrset( "Other1WinFlashTimer", "Enabled", 0)

    Ok = Vrset( "Other1ControlGB", "Visible", 1)

    CALL Setcolumnvisibility(5)
    Ok = Vrset("Other1Container", "Visible", 1)
    Ok = Vrset("Other1ContainerGB", "Visible", 1)
RETURN

/*:VRX         Other2Container_ContextMenu
*/
Other2container_contextmenu:
    CALL Vrmethod "AppEditMenu", "popup"
RETURN

/*:VRX         Other2Container_DoubleClick
*/
Other2container_doubleclick:
    CALL Edititem
RETURN

/*:VRX         Other2Container_DragDiscard
*/
Other2Container_DragDiscard: 
    CALL DragDiscard
return

/*:VRX         Other2Container_DragDrop
*/
Other2container_dragdrop:
    Record = Vrinfo( "Record" )
    Srcfile = Vrinfo( "SourceFile" )
    Container = Vrinfo("SourceObject")
    Targrec = Vrinfo("TargetRecord")

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
        Ok = Vrmethod( Vrinfo("TargetObject"), "SetFieldData", Targrec, Getfieldname(6, "I"), Value)
    END
        ELSE DO
            /* dropped on empty space */
            /* Create new record using the dropped icon */
            Ok = Addrec(6, Value)
        END

RETURN

/*:VRX         Other2DetailRB_Click
*/
Other2detailrb_click:
    /* zzzz enable sort menu */
    Ok = Vrsetini( Appname, "VIEW6", 2, Ininame )
    Ok = Sortarrange(6)
RETURN

/*:VRX         Other2IconRB_Click
*/
Other2iconrb_click:
    /* zzzz disable sort menu */
    Ok = Vrsetini( Appname, "VIEW6", 1, Ininame )
    Ok = Sortarrange(6)
RETURN

/*:VRX         Other2LargeIconRB_Click
*/
Other2largeiconrb_click:
    Ok = Vrset( "Other2Container", "MiniIcons", 0 )
    Ok = Vrsetini( Appname, "MINI6", 0, Ininame )
    CALL Sortarrange(6)
RETURN

/*:VRX         Other2NewButton_Click
*/
Other2newbutton_click:
    CALL Addrec(6)
RETURN

/*:VRX         Other2SmallIconRB_Click
*/
Other2smalliconrb_click:
    Ok = Vrset( "Other2Container", "MiniIcons", 1 )
    Ok = Vrsetini( Appname, "MINI6", 1, Ininame )
    CALL Sortarrange(6)
RETURN

/*:VRX         Other2Win_Close
*/
Other2win_close:
    CALL Saveprops
    CALL Other2win_fini
RETURN

/*:VRX         Other2Win_Create
*/
Other2win_create:
    CALL Other2win_init
RETURN

/*:VRX         Other2Win_Fini
*/
Other2win_fini:
    Window = Vrinfo( "Window" )
    CALL Vrdestroy Window
    DROP Window
RETURN
/*:VRX         Other2Win_Help
*/
Other2win_help:
    CALL Infhelp(Vrinfo("Source"))
RETURN

/*:VRX         Other2Win_Init
*/
Other2win_init:
    CALL Other2Win_LangInit /* do not modify or move this line! It must be on line #1 of this function */
    Window = Vrinfo( "Object" )
    /*
    IF( \Vrischildof( Window, "Notebook" ) ) THEN DO
        CALL Vrmethod Window, "CenterWindow"
        CALL Vrset Window, "Visible", 1
        CALL Vrmethod Window, "Activate"
    END
    */
    CALL Containerinit(6)
    CALL Container_langinit(6)
    CALL Restoreprops
    Other2wininited = 1
    DROP Window
RETURN





/*:VRX         Other2win_LangException
*/
Other2win_LangException: 
    call SetTickLabels(6) 

return

/*:VRX         Other2Win_LangInit
*/
Other2Win_LangInit:

    /* ------------------------------------------------ */
    /* Language internationalization code autogenerated */
    /* by VXNation v1.0, Copyright 1999, IDK, Inc.      */
    /*          http://www.idk-inc.com                  */
    /* Autogenerated: 03/06/2000 19:08:44             */
    /* ------------------------------------------------ */
    /* Warning! This code gets overwritten by VXNation! */
    /* Do not make modifications here!                  */
    /* ------------------------------------------------ */

    /* List of user specified secrets */
    Ok = VRSet("Other2Win", "HintText", VLSMsg(282))

    /* User Codes 2 */
    Ok = VRSet("Other2Container", "Caption", VLSMsg(77))

    /* List of user specified secrets */
    Ok = VRSet("Other2Container", "HintText", VLSMsg(282))

    /* Timer */
    Ok = VRSet("Other2WinFlashTimer", "Caption", VLSMsg(66))

    /* ;Dsc;Upd;Usr;S/N;Pw;Icon */
    MyTick.1 = VLSMsg(235)
    MyTick.2 = VLSMsg(236)
    MyTick.3 = VLSMsg(237)
    MyTick.4 = VLSMsg(103)
    MyTick.5 = VLSMsg(239)
    MyTick.6 = VLSMsg(99)
    MyTick.0 = 6
/*
    Ok = VRMethod("Other2SortSlide", "SetTickLabels", "MyTick.")
    DROP MyTick.

    Ok = VRSet("Other2SortSlide", "HintText", VLSMsg(46))
*/
    /* ~Large Icons */
    Ok = VRSet("Other2LargeIconRB", "Caption", VLSMsg(47))

    /* Selects Large icon size */
    Ok = VRSet("Other2LargeIconRB", "HintText", VLSMsg(48))

    /* ~Small Icons */
    Ok = VRSet("Other2SmallIconRB", "Caption", VLSMsg(49))

    /* Selects Small icon size */
    Ok = VRSet("Other2SmallIconRB", "HintText", VLSMsg(72))

    /* ~Icon View */
    Ok = VRSet("Other2IconRB", "Caption", VLSMsg(50))

    /* Select icon view of application codes */
    Ok = VRSet("Other2IconRB", "HintText", VLSMsg(51))

    /* ~Detail View */
    Ok = VRSet("Other2DetailRB", "Caption", VLSMsg(52))

    /* Select details view of application codes */
    Ok = VRSet("Other2DetailRB", "HintText", VLSMsg(53))

    /* I'm a logo! */
    Ok = VRSet("Pg6Icon", "HintText", VLSMsg(156))

    /* ~New */
    Ok = VRSet("Other2NewButton", "Caption", VLSMsg(54))

    /* Click to create a new record */
    Ok = VRSet("Other2NewButton", "HintText", VLSMsg(75))

    call Other2win_LangException
    DROP Ok

RETURN

/*:VRX         Other2Win_Resize
*/
Other2win_resize: PROCEDURE EXPOSE Lastheight Lastwidth
    IF Vrget( "DataNB", "Selected" ) <> 6 THEN DO
        RETURN
    END
    Ok = ContainerResize("Other2", 6)
RETURN

/*:VRX         Other2WinFlashTimer_Trigger
*/
Other2winflashtimer_trigger:
    Ok = Vrset("Other2Container", "Visible", 0)
    Ok = Vrmethod( "Other2Container", "SortRecords" )
    Ok = Vrmethod( "Other2Container", "Arrange" )

    CALL Other2win_langinit
    CALL Container_langinit(6)
    Ok = Vrset( "Other2WinFlashTimer", "Enabled", 0)

    Ok = Vrset( "Other2ControlGB", "Visible", 1)

    CALL Setcolumnvisibility(6)
    Ok = Vrset("Other2Container", "Visible", 1)
    Ok = Vrset("Other2ContainerGB", "Visible", 1)
RETURN

/*:VRX         Pass2Clip_Click
*/
Pass2clip_click:
    Ok = Vrmethod( Vrinfo("Source"), "GetRecordList", "SourceOrSelected", "SelectedRecs." )
    IF Selectedrecs.0 > 1 THEN DO
        Buttons.1 = Vlsmsg(80)                                  /* Ok */
        Buttons.0 = 1
        Id = Vrmessage( Vrwindow(), Vlsmsg(119) /* More than one item is selected */, Vlsmsg(120) /* Warning! */, "Warning", "Buttons.", , )
        RETURN
    END
    IF Selectedrecs.0 = 0 THEN DO
        Buttons.1 = Vlsmsg(80)                                  /* Ok */
        Buttons.0 = 1
        Id = Vrmessage( Vrwindow(), Vlsmsg(121) /* No item was selected */, Vlsmsg(120) /* Warning! */, "Warning", "Buttons.", , )
        RETURN
    END
    Value = Vrmethod(Vrinfo("Source"), "GetFieldData", SelectedRecs.1, Fieldvals. )
    Indx = GetFieldIndex(VRGet("DataNB", "Selected"), "P")
    Ok = Vrmethod("Application", "PutClipBoard", Fieldvals.Indx)
RETURN

/*:VRX         PaswordSort_Click
*/
PaswordSort_Click: 
    selected = VRGet( "DataNB", "Selected" )
    Ok = Vrsetini( Appname, "SORT" || Selected, 5, Ininame )
    CALL Sortarrange(Selected)

return

/*:VRX         Pg1Icon_ContextMenu
*/
Pg1icon_contextmenu:
    Ok = Vrmethod( "IconMenu", "Popup", , , "OpenIconFile", "" )
RETURN

/*:VRX         Pg1Icon_DragDrop
*/
Pg1icon_dragdrop:
    Record = Vrinfo( "Record" )
    Srcfile = Vrinfo( "SourceFile" )
    Container = Vrinfo("SourceObject")
    IF Srcfile = "" THEN DO
        Value = Vrmethod( Container, "GetRecordAttr", Record, "Icon" )
        Ok = Vrset( "Pg1Icon", "PicturePath", Value )
    END
        ELSE DO
            Ok = Vrset( "Pg1Icon", "PicturePath", Srcfile )
        END
    Ok = Krputpageicon(1, Vrget("Pg1Icon", "PicturePath"))
RETURN

/*:VRX         Pg2Icon_ContextMenu
*/
Pg2icon_contextmenu:
    Ok = Vrmethod( "IconMenu", "Popup", , , "OpenIconFileItem", "" )
RETURN

/*:VRX         Pg2Icon_DragDrop
*/
Pg2icon_dragdrop:
    Record = Vrinfo( "Record" )
    Srcfile = Vrinfo( "SourceFile" )
    Container = Vrinfo("SourceObject")
    IF Srcfile = "" THEN DO
        Value = Vrmethod( Container, "GetRecordAttr", Record, "Icon" )
        Ok = Vrset( "Pg2Icon", "PicturePath", Value )
    END
        ELSE DO
            Ok = Vrset( "Pg2Icon", "PicturePath", Srcfile )
        END
    Ok = Krputpageicon(2, Vrget("Pg2Icon", "PicturePath"))

RETURN

/*:VRX         Pg3Icon_ContextMenu
*/
Pg3icon_contextmenu:
    Ok = Vrmethod( "IconMenu", "Popup", , , "OpenIconFileItem", "" )

RETURN

/*:VRX         Pg3Icon_DragDrop
*/
Pg3icon_dragdrop:
    Record = Vrinfo( "Record" )
    Srcfile = Vrinfo( "SourceFile" )
    Container = Vrinfo("SourceObject")
    IF Srcfile = "" THEN DO
        Value = Vrmethod( Container, "GetRecordAttr", Record, "Icon" )
        Ok = Vrset( "Pg3Icon", "PicturePath", Value )
    END
        ELSE DO
            Ok = Vrset( "Pg3Icon", "PicturePath", Srcfile )
        END
    Ok = Krputpageicon(3, Vrget("Pg3Icon", "PicturePath"))
RETURN

/*:VRX         Pg4Icon_ContextMenu
*/
Pg4icon_contextmenu:
    Ok = Vrmethod( "IconMenu", "Popup", , , "OpenIconFileItem", "" )

RETURN

/*:VRX         Pg4Icon_DragDrop
*/
Pg4icon_dragdrop:
    Record = Vrinfo( "Record" )
    Srcfile = Vrinfo( "SourceFile" )
    Container = Vrinfo("SourceObject")
    IF Srcfile = "" THEN DO
        Value = Vrmethod( Container, "GetRecordAttr", Record, "Icon" )
        Ok = Vrset( "Pg4Icon", "PicturePath", Value )
    END
        ELSE DO
            Ok = Vrset( "Pg4Icon", "PicturePath", Srcfile )
        END
    Ok = Krputpageicon(4, Vrget("Pg4Icon", "PicturePath"))

RETURN

/*:VRX         Pg5Icon_ContextMenu
*/
Pg5icon_contextmenu:
    Ok = Vrmethod( "IconMenu", "Popup", , , "OpenIconFileItem", "" )

RETURN

/*:VRX         Pg5Icon_DragDrop
*/
Pg5icon_dragdrop:
    Record = Vrinfo( "Record" )
    Srcfile = Vrinfo( "SourceFile" )
    Container = Vrinfo("SourceObject")
    IF Srcfile = "" THEN DO
        Value = Vrmethod( Container, "GetRecordAttr", Record, "Icon" )
        Ok = Vrset( "Pg5Icon", "PicturePath", Value )
    END
        ELSE DO
            Ok = Vrset( "Pg5Icon", "PicturePath", Srcfile )
        END
    Ok = Krputpageicon(5, Vrget("Pg5Icon", "PicturePath"))

RETURN

/*:VRX         Pg6Icon_ContextMenu
*/
Pg6icon_contextmenu:
    Ok = Vrmethod( "IconMenu", "Popup", , , "OpenIconFileItem", "" )

RETURN

/*:VRX         Pg6Icon_DragDrop
*/
Pg6icon_dragdrop:
    Record = Vrinfo( "Record" )
    Srcfile = Vrinfo( "SourceFile" )
    Container = Vrinfo("SourceObject")
    IF Srcfile = "" THEN DO
        Value = Vrmethod( Container, "GetRecordAttr", Record, "Icon" )
        Ok = Vrset( "Pg6Icon", "PicturePath", Value )
    END
        ELSE DO
            Ok = Vrset( "Pg6Icon", "PicturePath", Srcfile )
        END
    Ok = Krputpageicon(6, Vrget("Pg6Icon", "PicturePath"))

RETURN

/*:VRX         PINContainer_ContextMenu
*/
Pincontainer_contextmenu:
    CALL Vrmethod "AppEditMenu", "popup"
RETURN

/*:VRX         PINContainer_DoubleClick
*/
Pincontainer_doubleclick:
    CALL Edititem
RETURN

/*:VRX         PINContainer_DragDiscard
*/
PINContainer_DragDiscard: 
    CALL DragDiscard
return

/*:VRX         PINContainer_DragDrop
*/
Pincontainer_dragdrop:
    Record = Vrinfo( "Record" )
    Srcfile = Vrinfo( "SourceFile" )
    Container = Vrinfo("SourceObject")
    Targrec = Vrinfo("TargetRecord")

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
        Ok = Vrmethod( Vrinfo("TargetObject"), "SetFieldData", Targrec, Getfieldname(3, "I"), Value)
    END
        ELSE DO
            /* dropped on empty space */
            /* Create new record using the dropped icon */
            Ok = Addrec(3, Value)
        END

RETURN

/*:VRX         PINDetailRB_Click
*/
Pindetailrb_click:
    /* zzzz enable sort menu */
    Ok = Vrsetini( Appname, "VIEW3", 2, Ininame )
    Ok = Sortarrange(3)
RETURN

/*:VRX         PINIconRB_Click
*/
Piniconrb_click:
    /* zzzz disable sort menu */
    Ok = Vrsetini( Appname, "VIEW3", 1, Ininame )
    Ok = Sortarrange(3)
RETURN

/*:VRX         PINLargeIconRB_Click
*/
Pinlargeiconrb_click:
    Ok = Vrset( "PINContainer", "MiniIcons", 0 )
    Ok = Vrsetini( Appname, "MINI3", 0, Ininame )
    CALL Sortarrange(3)
RETURN

/*:VRX         PINNewButton_Click
*/
Pinnewbutton_click:
    CALL Addrec(3)
RETURN

/*:VRX         PINSmallIconRB_Click
*/
Pinsmalliconrb_click:
    Ok = Vrset( "PINContainer", "MiniIcons", 1 )
    Ok = Vrsetini( Appname, "MINI3", 1, Ininame )
    CALL Sortarrange(3)
RETURN

/*:VRX         PINWin_Close
*/
Pinwin_close:
    CALL Saveprops
    CALL Pinwin_fini
RETURN

/*:VRX         PINWin_Create
*/
Pinwin_create:
    CALL Pinwin_init
RETURN

/*:VRX         PINWin_Fini
*/
Pinwin_fini:
    Window = Vrinfo( "Window" )
    CALL Vrdestroy Window
    DROP Window
RETURN
/*:VRX         PINWin_Help
*/
Pinwin_help:
    CALL Infhelp(Vrinfo("Source"))

RETURN

/*:VRX         PINWin_Init
*/
Pinwin_init:
    CALL PINWin_LangInit /* do not modify or move this line! It must be on line #1 of this function */
    Window = Vrinfo( "Object" )
    /*
    IF( \Vrischildof( Window, "Notebook" ) ) THEN DO
        CALL Vrmethod Window, "CenterWindow"
        CALL Vrset Window, "Visible", 1
        CALL Vrmethod Window, "Activate"
    END
    */
    CALL Containerinit(3)
    CALL Container_langinit(3)
    CALL Restoreprops
    Pinwininited = 1
    DROP Window
RETURN



/*:VRX         PINWin_LangException
*/
PINWin_LangException: 
    call SetTickLabels(3) 

return

/*:VRX         PINWin_LangInit
*/
PINWin_LangInit:

    /* ------------------------------------------------ */
    /* Language internationalization code autogenerated */
    /* by VXNation v1.0, Copyright 1999, IDK, Inc.      */
    /*          http://www.idk-inc.com                  */
    /* Autogenerated: 03/06/2000 19:08:43             */
    /* ------------------------------------------------ */
    /* Warning! This code gets overwritten by VXNation! */
    /* Do not make modifications here!                  */
    /* ------------------------------------------------ */

    /* Bank and credit card PIN numbers */
    Ok = VRSet("PINWin", "HintText", VLSMsg(67))

    /* PIN Numbers */
    Ok = VRSet("PINContainer", "Caption", VLSMsg(68))

    /* List of bank and credit card personal ID numbers */
    Ok = VRSet("PINContainer", "HintText", VLSMsg(280))

    /* Timer */
    Ok = VRSet("PinWinFlashTimer", "Caption", VLSMsg(66))

    /* ;Dsc;Upd;Usr;S/N;Pw;Icon */
    MyTick.1 = VLSMsg(235)
    MyTick.2 = VLSMsg(236)
    MyTick.3 = VLSMsg(237)
    MyTick.4 = VLSMsg(103)
    MyTick.5 = VLSMsg(239)
    MyTick.6 = VLSMsg(99)
    MyTick.0 = 6
/*
    Ok = VRMethod("PINSortSlide", "SetTickLabels", "MyTick.")
    DROP MyTick.

    /* Change Address sort order */
    Ok = VRSet("PINSortSlide", "HintText", VLSMsg(46))
*/
    /* ~Large Icons */
    Ok = VRSet("PINLargeIconRB", "Caption", VLSMsg(47))

    /* Selects Large icon size */
    Ok = VRSet("PINLargeIconRB", "HintText", VLSMsg(48))

    /* ~Small Icons */
    Ok = VRSet("PINSmallIconRB", "Caption", VLSMsg(49))

    /* Selects Small icon size */
    Ok = VRSet("PINSmallIconRB", "HintText", VLSMsg(72))

    /* ~Icon View */
    Ok = VRSet("PINIconRB", "Caption", VLSMsg(50))

    /* Select icon view of application codes */
    Ok = VRSet("PINIconRB", "HintText", VLSMsg(51))

    /* ~Detail View */
    Ok = VRSet("PINDetailRB", "Caption", VLSMsg(52))

    /* Select details view of application codes */
    Ok = VRSet("PINDetailRB", "HintText", VLSMsg(53))

    /* I'm a logo! */
    Ok = VRSet("Pg3Icon", "HintText", VLSMsg(156))

    /* ~New */
    Ok = VRSet("PINNewButton", "Caption", VLSMsg(54))

    /* Click to create a new record */
    Ok = VRSet("PINNewButton", "HintText", VLSMsg(75))

    call PINWin_LangException
    DROP Ok

RETURN

/*:VRX         PINWin_Resize
*/
Pinwin_resize: PROCEDURE EXPOSE Lastheight Lastwidth
    IF Vrget( "DataNB", "Selected" ) <> 3 THEN DO
        RETURN
    END
    Ok = ContainerResize("PIN", 3)
RETURN

/*:VRX         PinWinFlashTimer_Trigger
*/
Pinwinflashtimer_trigger:
    Ok = Vrset("PinContainer", "Visible", 0)
    Ok = Vrmethod( "PinContainer", "SortRecords" )
    Ok = Vrmethod( "PinContainer", "Arrange" )

    CALL Pinwin_langinit
    CALL Container_langinit(3)
    Ok = Vrset( "PINWinFlashTimer", "Enabled", 0)

    Ok = Vrset( "PINControlGB", "Visible", 1)

    CALL Setcolumnvisibility(3)
    Ok = Vrset("PINContainer", "Visible", 1)
    Ok = Vrset("PINContainerGB", "Visible", 1)
RETURN

/*:VRX         PrintItem_Click
*/
Printitem_click:
/*
    PDButs.0 = 3 
    PDButs.1 = "~Accept"
    PDButs.2 = "~Job Properties"
    PDButs.3 = "Cancel"
    PrnName = VRMethod( "PRT_1", "PrinterDialog", "Select a printer", "PDButs.");
    if PrnName = '' then
        return

    Define the table 

    table.0 = 11
    table.1 = 0
    table.2 = 28
    table.3 = 1
    table.4 = 0
    table.5 = 28
    table.6 = 1
    table.7 = 12
    table.8 = 'Helvetica Bold'
    table.9 = 0
    table.10 = 15
    table.11 = 15

    formwidth = VRGet( "PRT_1", "FormWidth" ) - 20;

    do page = 1 to 1
        ok = VRMethod( "PRT_1", "SetMargins", 10, 10, 20, 25, 0, 0, "<default>", "<default>" );
        ok = VRMethod( "PRT_1", "SetHeaderMode", 1, "Helv", 10, 8, 26, 1, "<default>", "<default>", "<default>" );
        ok = VRMethod( "PRT_1", "SetHeader", 2, "$c| " || Getpagename(240 + Page, Page), "$cIDK, Inc.");
        ok = VRMethod( "PRT_1", "SetHeaderLineFont", 1, "Helv", 15);
        ok = VRMethod( "PRT_1", "SetHeaderLineFont", 2, "Helv", 11);
        ok = VRMethod( "PRT_1", "SetHeaderLineFont", 3, "Helv", 8);
        ok = VRMethod( "PRT_1", "SetFooter", "Helv", 10, 8, 14, "$@ $?$rPage $#", "<default>", "<default>", "<default>" );

        Ok = PrintPage(Page)
    end
*/
RETURN

/*:VRX         PrintPage
*/
PrintPage: 
/*
    Page = ARG(1)

    ok = VRMethod( "PRT_1", "OpenPrintJob", "KeyRing/2 " || Getpagename(240 + Page, Page) ||" Records");
    rcy = VRMethod( "PRT_1", "PrintLine", "Helv", 12,'');

    ColumnCount = GetColCount(Page);
    Cols.0.0 = ColumnCount
    FormWidth = VRGet( "PRT_1", "FormWidth" ) - 20;
    ColCounter = 1

    if ColumnCount <> 9 then do
        IconWidth = Trunc( (0.0686 * FormWidth)+0.5, "0" )
        RemainingPct = 1.0 - IconWidth
        ColWidth = RemainingPct / (ColumnCount - 1)
        do I = 1 to 9
            Colstr = Krgetcolumnenable(Page, I)
            PARSE VAR Colstr Enb "þ" Flag "þ" Hint
            ColFlg.I = Flag
            IF Enb = 1 THEN DO
                IF Flag = "I" THEN DO
                    Cols.ColCounter.1 = IconWidth
                END
                ELSE DO
                    Cols.ColCounter.1 = ColWidth
                END
                Cols.ColCounter.2 = GetColumnName(Page, I)
                ColCounter = ColCounter + 1
            END
        end        
    end
    else do
         dynamically set up column widths for this page 
        do i = 1 to 9
            Cols.I.2 = "$c" || Getcolumnname(98+I, Page, I)
            Colstr = Krgetcolumnenable(Page, I)
            PARSE VAR Colstr Enb "þ" Flag "þ" Hint
            ColFlg.I = Flag
            select
                when Flag = "I" then do
                    Cols.I.1 = Trunc( (0.0686 * FormWidth)+0.5, "0" )
                end
                when Flag = "D" then do
                    Cols.I.1 = Trunc( (0.097142 * FormWidth)+0.5, "0" )
                end
                when Flag = "N" then do
                    Cols.I.1 = Trunc( (0.097142 * FormWidth)+0.5, "0" )
                end
                when Flag = "P" then do
                    Cols.I.1 = Trunc( (0.097142 * FormWidth)+0.5, "0" )
                end
                when Flag = "S" then do
                    Cols.I.1 = Trunc( (0.097142 * FormWidth)+0.5, "0" )
                end
                when Flag = "L" then do
                    Cols.I.1 = Trunc( (0.097142 * FormWidth)+0.5, "0" )
                end
                when Flag = "E" then do
                    Cols.I.1 = Trunc( (0.097142 * FormWidth)+0.5, "0" )
                end
                when Flag = "U" then do
                    Cols.I.1 = Trunc( (0.2 * FormWidth)+0.5, "0" )
                end
                when Flag = "W" then do
                    Cols.I.1 = Trunc( (0.15428 * FormWidth)+0.5, "0" )
                end
                otherwise do
                    Cols.I.1 = Trunc( (0.0686 * FormWidth)+0.5, "0" )
                end
             end
        end
    end;
    
    rcy = VRMethod( "PRT_1", "DefineTable", "table.", "Cols.");

    if rcy then do
        hmod = VRMethod( "PRT_1", "LoadResMod", "kricon");

        DO I = 1 TO Krgetreccount(Page)
            rcy = VRMethod( "PRT_1", "StartRow");
            DO J = 1 to Cols.0.0
                Value = KRGetFieldVal(Page, I, ColFlg.J)
                if Colflg.J = "I" THEN DO
                    if substr(Value, 1,1) = "$" then do
                        say "**********"
                        say "orig " || value
                        parse var Value "$" Resnum ":" DllName
                        if dllname = "" then do
                            dllname = "kricon"
                        END
                        say "resnum " || resnum 
                        say "dllname " || dllname
                        Value = "g:\keyring2\graphics\edit.ico"
                        Value = hmod || "$" || (Resnum + 1000)
                        say "new value " || value
                        say "colflg " || colflg.j
                    end
                end
                rcy = VRMethod( "PRT_1", "StartCol", J)
                IF ColFlg.J = "I" THEN DO
                    rcy = VRMethod( "PRT_1", "PrintBitMap", Value,,,,,,,"");
                    say "pbm value = " || Value 
                    say "Rcy = " || Rcy
                end
                else do
                    rcy = VRMethod( "PRT_1", "PrintLeft", 'Helv', 8, Value);
                end
            end
            rcy = VRMethod( "PRT_1", "EndRow");
        end
        call VRMethod "PRT_1", "FreeResMod", hmod
        rcy = VRMethod( "PRT_1", "EndTable");
    end    
    else
        rcy = VRMethod( "PRT_1", "PrintLine", 'Helvetica Bold', 14, 'ERROR - Failed to create the table...');
    
    ok = VRMethod( "PRT_1", "ClosePrintJob" )
*/
return 1

/*:VRX         ProductInfoItem1_Click
*/
Productinfoitem1_click:
    Rc = About(Vrwindow(), "KR2", "KR2.INI")
RETURN

/*:VRX         Quit
*/
Quit:
    Ok = Vrmethod("Application", "PutClipBoard", "")/* clear the clipboard */
    IF DirtyFlag = 1 THEN DO
        CALL Updatedbfromcontainers
        CALL Killhat 
        DirtyFlag = 0
    END
    call waitmouse
    CALL Saveprops
    Ok = Vrsetini( Appname, "MainHeight", Vrget( "MainWin", "Height" ), Ininame )
    Ok = Vrsetini( Appname, "MainWidth", Vrget( "MainWin", "Width" ), Ininame )
    Ok = Vrsetini( Appname, "MainTop", Vrget( "MainWin", "Top" ), Ininame )
    Ok = Vrsetini( Appname, "MainLeft", Vrget( "MainWin", "Left" ), Ininame )
    Ok = Vrsetini( Appname, "StickyPage", VRGet( "DataNB", "Selected" ), Ininame )

    CALL Normalmouse

    Window = Vrwindow()
    CALL Vrset Window, "Shutdown", 1
    DROP Window
RETURN

/*:VRX         Quit1_Click
*/
Quit1_click:
    CALL Quit
RETURN

/*:VRX         QuitButton_Click
*/
Quitbutton_click:
    CALL Quit
RETURN

/*:VRX         ReInitPages
*/
Reinitpages: PROCEDURE EXPOSE Contnames.
    Selected = Vrget( "DataNB", "Selected" )
    DO I = 1 TO 7
        Ok = Vrmethod("DataNB", "DeletePage", I)
        W = Vrload("DataNB", Vrwindowpath(), Contnames.i || "Win")
        Ok = Vrmethod("DataNB", "InsertPage", W, "+" || Getpagename(240 + I, I), I)
    END
    Ok = Vrset("DataNB", "Selected", Selected)
    CALL Normalmouse
    
RETURN

/*:VRX         SaveButton_Click
*/
Savebutton_click:
    CALL Updatedbfromcontainers
    CALL Killhat

RETURN

/*:VRX         SaveFile
*/
Savefile:
    CALL Updatedbfromcontainers
    CALL Killhat

RETURN

/*:VRX         SaveProps
*/
Saveprops:
    IF Vrgetini( Appname, "CustomFontCB", Ininame, "NOCLOSE" ) <> "1" THEN do
        RETURN
    end
    do x = 1 to Contnames.0 - 1 /* don't do boss container */
        Obj = Contnames.x||"Container"
        Initstrg = Vrget(Obj, "font") || "þ" Vrget(Obj, "forecolor") || "þ" Vrget(Obj, "backcolor")
        Ok = Vrsetini( Appname, Obj, Initstrg, Ininame, "NOCLOSE" )
    end
    RETURN    

    /* this is obsolete (and slow) */
    Ok = Vrmethod( Vrget(Vrwindow(), "name"), "ListChildren", "child." )
    Lastchild=Child.0+1
    Child.lastchild = Vrget(Vrwindow(), "name")
    Child.0 = Lastchild
    Initstrg = ""
    DO X = 1 TO Child.0
        IF Vrmethod( "Application", "SupportsProperty", Child.x , "font" ) = 1 THEN DO
            IF Vrmethod( "Application", "SupportsProperty", Child.x , "forecolor" ) = 1 THEN DO
                IF Vrmethod( "Application", "SupportsProperty", Child.x , "backcolor" ) = 1 THEN DO
                    Initstrg = Vrget(Child.x, "font") || "þ" Vrget(Child.x, "forecolor") || "þ" Vrget(Child.x, "backcolor")
                    Ok = Vrsetini( Appname, Vrget(Child.x, "Name"), Initstrg, Ininame, "NOCLOSE" )
                END
            END
        END
    END
RETURN

/*:VRX         ScanWindows
*/
Scanwindows:
    Ok = Vrmethod("Screen", "ListWindows", Windows.)
    IF Ok = 1 THEN DO
        DO I = 1 TO Windows.0
            W = WORD(Windows.i, 1)
            IF Vrget(W, "Visible") = 1 THEN DO
                IF POS( "Netscape", Vrget(W, "Caption"), 1 ) = 1 THEN DO
                    RETURN W
                END
            END
        END
    END
RETURN ""

/*:VRX         SelInternalLogoIcon_Click
*/
Selinternallogoicon_click:
    Iconselthreadid = Vrmethod( "Application", "StartThread", "IconSel", Appname, Ininame )
RETURN

/*:VRX         SerialNumberSort_Click
*/
SerialNumberSort_Click: 
    selected = VRGet( "DataNB", "Selected" )
    Ok = Vrsetini( Appname, "SORT" || Selected, 4, Ininame )
    CALL Sortarrange(Selected)

return

/*:VRX         SetDefaultView
*/
SetDefaultView: 
        Order = KRGetDefaultOrder()
        DO I = 1 TO 6
            DO J = 1 TO 9
                H = Getdefaulthinttext(J)
                A = GetDefaultAbbrev(J)
                ColName = Vlsmsg(98+J)/* use default name */
                Flag = SUBSTR(Order, J, 1)
                Ok = KRPutColumnEnable(I, J, 1, Flag, H, A )
            END
            Ok = KRPutPageHint(I, Vlsmsg(I + 277))
        END
        drop h a i j
return 1

/*:VRX         SetFieldVal
*/
SetFieldVal: PROCEDURE EXPOSE ContNames.
    SfPage = ARG(1)
    SfRec  = ARG(2)
    SfFlag = ARG(3)
    SfVal  = ARG(4)

    Cont = ContNames.SfPage || "Container"

    Ok  = VRMethod(Cont, "GetFieldList", "SfFields." )
    Sfi = GetFieldIndex(SfPage, SfFlag)
    Ok = Vrmethod(Cont, "SetFieldData", SfRec, SfFields.Sfi, SfVal)

    DROP SfPage SfFlag SfRec SFVal Sfi Cont
return Ok

/*:VRX         SetIcon
*/
Seticon:
    PARSE ARG Pg
    Value = Krgetpageicon(Pg)
    IF Value = "" THEN DO
        Value = Pglogo.pg
    END
RETURN Value

/*:VRX         SetIcons
*/
Seticons:
    DO I = 1 TO 6
        Iconname = "Pg" || I || "Icon"
        Ok = Vrset(Iconname, "PicturePath", Seticon(I))
    END
    DROP Iconname
RETURN

/*:VRX         SetTabs
*/
Settabs: PROCEDURE EXPOSE Contnames.
    DO I = 1 TO 6
        Cont = Contnames.i || "Container"
        Ok = Vrmethod(Cont, "GetFieldList", "Fields.")
        Value = Getpagename(240 + I, I)
        Ok = Vrmethod("DataNB", "SetTabText", I, Value)
        IF Fields.0 = 10 THEN DO
            Ok = Vrset(Cont, "Caption", Value)        
        END
    END
RETURN

/*:VRX         SetTickLabels
*/
SetTickLabels: 
    Pgz = Arg(1)

    /* set defaults for current language */
    MyTick.1 = VLSMsg(235)
    MyTick.2 = VLSMsg(236)
    MyTick.3 = VLSMsg(237)
    MyTick.4 = VLSMsg(103)
    MyTick.5 = VLSMsg(239)
    MyTick.6 = VLSMsg(99)
    MyTick.0 = 6
    do Iz = 1 to TickMap.0 
       Valuez = GetTickLabel(Pgz, TickMap.iz) /* get the label override (if any) for this tick */
       if Valuez <> "" then do
            MyTick.Iz = Valuez
       end  
    end

/*    Ok = VRMethod(ContNames.Pgz || "SortSlide", "SetTickLabels", "MyTick.") */
    DROP MyTick. Iz Valuez Pgz
return

/*:VRX         SetupButton_Click
*/
Setupbutton_click:
    CALL Setupitem_click
RETURN

/*:VRX         SetupItem_Click
*/
Setupitem_click:
    call UpdateTree
    Ok = Setup1(Vrwindow(), Appname, Ininame)
    Ok = Vrset( "DataNB", "Visible", 0 )
    CALL Reinitpages
    CALL Restoreprops
    CALL Settabs
    Ok = Vrset( "DataNB", "Visible", 1 )
RETURN

/*:VRX         UpdateContainersFromTree
*/
Updatecontainersfromtree: PROCEDURE EXPOSE Contnames. Iniloaded Showpw
    CALL Waitmouse

    DO Index = 1 TO 6
        Cont = Contnames.index || "Container"
        Ok = Vrset(Cont, "Visible", 0 )
        CALL Containerinit(Index)
        CALL Restoreprops
        CALL Settabs
        Ok = Vrset(Cont, "Visible", 1 )
    END
    CALL Normalmouse
    DROP Index
RETURN

/*:VRX         UpdateDBFromContainers
*/
Updatedbfromcontainers:
    CALL Launchhat
    Ok = Updatetreefromcontainer("WWWContainer", 1)
    Ok = Updatetreefromcontainer("AppContainer", 2)
    Ok = Updatetreefromcontainer("PINContainer", 3)
    Ok = Updatetreefromcontainer("ComboContainer", 4)
    Ok = Updatetreefromcontainer("Other1Container", 5)
    Ok = Updatetreefromcontainer("Other2Container", 6)

    IF Password <> "" THEN DO
        IF Db <> "" THEN DO
            Generations = Vrgetini( Appname, "BackupGenerationSpinner", Ininame )
            IF Generations = "" THEN do
                Generations = 0
            end
            Ok = Krsaveini(Vrgetini( Appname, "DB", Ininame ), Password, 1, Generations)
        END
    end
    DirtyFlag = 0;
return 1
/*:VRX         UpdateDBFromContainers_Click
*/
Updatedbfromcontainers_click:
    CALL Updatedbfromcontainers
    CALL Killhat

RETURN

/*:VRX         UpdateSort_Click
*/
UpdateSort_Click: 
    selected = VRGet( "DataNB", "Selected" )
    Ok = Vrsetini( Appname, "SORT" || Selected, 2, Ininame )
    CALL Sortarrange(Selected)

return

/*:VRX         UpdateTree
*/
Updatetree: PROCEDURE EXPOSE Contnames.
    DO Indxu = 1 TO 6
        Cont = Contnames.indxu || "Container"
        Ok = Vrmethod(Cont, "GetFieldList", "zfields.")
        Ok = Updatetreefromcontainer(Cont, Indxu)
    END
    DROP Indxu
RETURN

/*:VRX         UpdateTreeFromContainer
*/
Updatetreefromcontainer:
    Cont = ARG(1)
    Rectype = ARG(2)
    Ok = Krkillbranch(Rectype)
    Ok = Vrmethod( Cont, "GetRecordList", "All", "RecList." )
    DO I = 1 TO Reclist.0
        Ok = Vrmethod(Cont, "GetFieldData", Reclist.i, "Fieldvals.")
        Ok = Krputrec(Rectype, I, Fieldvals.10, Fieldvals.1, Fieldvals.2, Fieldvals.3, Fieldvals.4, Fieldvals.5, Fieldvals.6, Fieldvals.7, Fieldvals.8, Fieldvals.9)
    END
RETURN 1

/*:VRX         URLItem_Click
*/
Urlitem_click:
    CALL Browserbutton_click
RETURN

/*:VRX         UserNameSort_Click
*/
UserNameSort_Click: 
    selected = VRGet( "DataNB", "Selected" )
    Ok = Vrsetini( Appname, "SORT" || Selected, 3, Ininame )
    CALL Sortarrange(Selected)
return

/*:VRX         UsingHelpItem1_Click
*/
Usinghelpitem1_click:
    CALL Infhelp(Vrinfo("Source"))

RETURN

/*:VRX         WaitForBrowser
*/
Waitforbrowser:
    Lasttime = 45
    Ok = Vrset("BrowserTimer", "Delay", 1000 )
    Ok = Vrset("BrowserTimer", "Enabled", "1" )
RETURN 0

/*:VRX         WaitForHatToDie
*/
Waitforhattodie:
    Ok = Vrset( "HatDeadmanTimer", "Enabled", 1 )
RETURN

/*:VRX         WWWContainer_ContextMenu
*/
Wwwcontainer_contextmenu:
    CALL Vrmethod "AppEditMenu", "popup"
RETURN

/*:VRX         WWWContainer_DoubleClick
*/
Wwwcontainer_doubleclick:
    CALL Edititem
RETURN

/*:VRX         WWWContainer_DragDiscard
*/
WWWContainer_DragDiscard: 
    CALL DragDiscard
return

/*:VRX         WWWContainer_DragDrop
*/
Wwwcontainer_dragdrop:
    Record = Vrinfo( "Record" )
    Srcfile = Vrinfo( "SourceFile" )
    Container = Vrinfo("SourceObject")
    Targrec = Vrinfo("TargetRecord")
    
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
        Ok = Vrmethod( Vrinfo("TargetObject"), "SetFieldData", Targrec, Getfieldname(1, "I"), Value)
    END
    ELSE DO
            /* dropped on empty space */
            /* Create new record using the dropped icon */
            Ok = Addrec(1, Value)
        END
RETURN

/*:VRX         WWWContainer_KeyPress
*/
WWWContainer_KeyPress: 
    keystring = VRGet( "WWWContainer", "KeyString" )
    call vrset "WWWContainer", "KeyString", Keystring
return

/*:VRX         WWWDetailRB_Click
*/
Wwwdetailrb_click:
    /* zzzz enable sort menu */
    Ok = Vrsetini( Appname, "VIEW1", 2, Ininame )
    Ok = Sortarrange(1)
RETURN

/*:VRX         WWWIconRB_Click
*/
Wwwiconrb_click:
    /* zzzz disable sort menu */
    Ok = Vrsetini( Appname, "VIEW1", 1, Ininame )
    Ok = Sortarrange(1)
RETURN

/*:VRX         WWWLargeIconRB_Click
*/
Wwwlargeiconrb_click:
    Ok = Vrset( "WWWContainer", "MiniIcons", 0 )
    Ok = Vrsetini( Appname, "MINI1", 0, Ininame )
    CALL Sortarrange(1)
RETURN

/*:VRX         WWWNewButton_Click
*/
Wwwnewbutton_click:
    CALL Addrec(1)
RETURN

/*:VRX         WWWSmallIconRB_Click
*/
Wwwsmalliconrb_click:
    Ok = Vrset( "WWWContainer", "MiniIcons", 1 )
    Ok = Vrsetini( Appname, "MINI1", 1, Ininame )
    CALL Sortarrange(1)
RETURN

/*:VRX         WWWWin_Close
*/
Wwwwin_close:
    CALL Saveprops
    CALL Wwwwin_fini
RETURN

/*:VRX         WWWWin_Create
*/
Wwwwin_create:
    CALL Wwwwin_init
RETURN

/*:VRX         WWWWin_Fini
*/
Wwwwin_fini:
    Window = Vrinfo( "Window" )
    CALL Vrdestroy Window
    DROP Window
RETURN
/*:VRX         WWWWin_Help
*/
Wwwwin_help:
    CALL Infhelp(Vrinfo("Source"))

RETURN

/*:VRX         WWWWin_Init
*/
Wwwwin_init:
    CALL WWWWin_LangInit /* do not modify or move this line! It must be on line #1 of this function */
    CALL Containerinit(1)
    CALL Container_langinit(1)
    CALL Restoreprops
    Wwwwininited = 1
RETURN





/*:VRX         WWWWin_LangException
*/
WWWWin_LangException: 
    call SetTickLabels(1) 

return

/*:VRX         WWWWin_LangInit
*/
WWWWin_LangInit:

    /* ------------------------------------------------ */
    /* Language internationalization code autogenerated */
    /* by VXNation v1.0, Copyright 1999, IDK, Inc.      */
    /*          http://www.idk-inc.com                  */
    /* Autogenerated: 03/06/2000 19:08:43             */
    /* ------------------------------------------------ */
    /* Warning! This code gets overwritten by VXNation! */
    /* Do not make modifications here!                  */
    /* ------------------------------------------------ */

    /* Web, Email and ISP passwords */
    Ok = VRSet("WWWWin", "HintText", VLSMsg(63))

    /* Internet Passwords */
    Ok = VRSet("WWWContainer", "Caption", VLSMsg(64))

    /* List of Internet passwords */
    Ok = VRSet("WWWContainer", "HintText", VLSMsg(278))

    /* Timer */
    Ok = VRSet("WWWWinFlashTimer", "Caption", VLSMsg(66))

    /* dummy */
    Ok = VRSet("DummyDT", "Caption", VLSMsg(251))

    /* ;Dsc;Upd;Usr;S/N;Pw;Icon */
    MyTick.1 = VLSMsg(235)
    MyTick.2 = VLSMsg(236)
    MyTick.3 = VLSMsg(237)
    MyTick.4 = VLSMsg(103)
    MyTick.5 = VLSMsg(239)
    MyTick.6 = VLSMsg(99)
    MyTick.0 = 6
/*
    Ok = VRMethod("WWWSortSlide", "SetTickLabels", "MyTick.")
    DROP MyTick.

    /* Change Address sort order */
    Ok = VRSet("WWWSortSlide", "HintText", VLSMsg(46))
*/
    /* ~Large Icons */
    Ok = VRSet("WWWLargeIconRB", "Caption", VLSMsg(47))

    /* Selects Large icon size */
    Ok = VRSet("WWWLargeIconRB", "HintText", VLSMsg(48))

    /* ~Small Icons */
    Ok = VRSet("WWWSmallIconRB", "Caption", VLSMsg(49))

    /* Selects Small icon size */
    Ok = VRSet("WWWSmallIconRB", "HintText", VLSMsg(72))

    /* ~Icon View */
    Ok = VRSet("WWWIconRB", "Caption", VLSMsg(50))

    /* Select icon view of application codes */
    Ok = VRSet("WWWIconRB", "HintText", VLSMsg(51))

    /* ~Detail View */
    Ok = VRSet("WWWDetailRB", "Caption", VLSMsg(52))

    /* Select details view of application codes */
    Ok = VRSet("WWWDetailRB", "HintText", VLSMsg(53))

    /* ~New */
    Ok = VRSet("WWWNewButton", "Caption", VLSMsg(54))

    /* Click to create a new record */
    Ok = VRSet("WWWNewButton", "HintText", VLSMsg(75))

    /* I'm a logo! */
    Ok = VRSet("Pg1Icon", "HintText", VLSMsg(156))

    call WWWWin_LangException
    DROP Ok

RETURN

/*:VRX         WWWWin_Resize
*/
Wwwwin_resize: PROCEDURE EXPOSE Lastheight Lastwidth Forceresize
    IF Vrget( "DataNB", "Selected" ) <> 1 THEN DO
        RETURN
    END
    Ok = ContainerResize("WWW", 1)
RETURN

/*:VRX         WWWWinFlashTimer_Trigger
*/
Wwwwinflashtimer_trigger:
    Ok = Vrset( "WWWContainer", "Visible", 0)
    Ok = Vrmethod( "WWWContainer", "SortRecords" )
    Ok = Vrmethod( "WWWContainer", "Arrange" )

    /*
    CALL Wwwwin_langinit
    CALL Container_langinit(1)
    CALL SetColumnVisibility(1)
    */
    Ok = Vrset( "WWWWinFlashTimer", "Enabled", 0)
    Ok = Vrset( "WWWContainer", "Visible", 1 )

    Ok = Vrset("WWWContainerGB", "Visible", 1)
    Ok = Vrset( "WWWControlGB", "Visible", 1)
    Ok = Vrset( "WWWControlGB", "Enabled", 1)

RETURN

