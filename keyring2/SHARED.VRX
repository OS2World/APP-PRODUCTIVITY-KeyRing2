/*:VRX         Main
*/
Main:
    signal on halt


exit

/*:VRX         __VXREXX____APPENDS__
*/
__VXREXX____APPENDS__:
/*
*/
return
/*:VRX         ConfigWinControls
*/
Configwincontrols:
    Win = ARG(1)
    Sortindex = ARG(2)
    View = ARG(3)
    Mini = ARG(4)
    Sorttick = ARG(5)

    IF View = 1 THEN DO
        Ok = Vrset(Win || "container", "view", "Icon")
        Ok = Vrset( Win || "IconRB", "Set", 1 )
        Ok = Vrset( Win || "DetailRB", "Set", 0 )
    END
        ELSE DO
            Ok = Vrset(Win || "container", "view", "Detail")
            Ok = Vrset(Win || "IconRB", "Set", 0 )
            Ok = Vrset(Win || "DetailRB", "Set", 1 )
            Ok = Vrset( Win || "Container", "DetailSort", Sortindex)
        END

    IF Mini = 1 THEN DO
        Ok = Vrset( Win || "SmallIconRB", "Set", 1 )
        Ok = Vrset( Win || "LargeIconRB", "Set", 0 )
    END
        ELSE DO
            Ok = Vrset( Win || "SmallIconRB", "Set", 0 )
            Ok = Vrset( Win || "LargeIconRB", "Set", 1 )
        END

    Ok = Vrset( Win || "Container", "MiniIcons", Mini )

    Ok = Vrmethod( Win || "Container", "SortRecords" )

    IF View = 0 THEN DO
        Ok = Vrmethod( Win || "Container", "Arrange" )
    END

RETURN 1


/*:VRX         Container_LangInit
*/
Container_langinit: PROCEDURE EXPOSE Contnames.
    Conttype = ARG(1)
    Contname = Contnames.conttype || "Container"
    Ok = Vrmethod( Contname, "GetFieldList", "FieldID." )

    DO I = 1 TO 9
        Fld= "F" || I
        Colname = Getcolumnname(98+I, Conttype, I)
        Ok = Vrmethod( Contname, "SetFieldAttr", Fieldid.i, "Title", Colname )
    END
RETURN

/*:VRX         ContainerInit
*/
Containerinit: PROCEDURE EXPOSE Iniloaded Contnames. Fieldnames. Showpw Initinprogress Appname Ininame
    Conttype = ARG(1)
    Contname = Contnames.conttype || "Container"
    Ok = Vrset(Contname, "Visible", 0)
    CALL Waitmouse
    BMPFile = VRGetIni( "KR2", "PG" || ContType || "BMP", "KR2.INI" )
    if BMPFile <> "" THEN DO
        ok = VRSet( ContName, "PicturePath", BMPFile )
    END
    Initinprogress = 0
    Ok = Vrmethod( Contname, "GetFieldList", "FieldID." )

    IF Fieldid.0 <> 10 THEN DO
        DO I = 1 TO 9
            Colstr = Krgetcolumnenable(Conttype, I)
            PARSE VAR Colstr Enb "�" Flag "�" Hint
            IF Flag = "I" THEN DO
                Style = "Icon"
            END
                ELSE DO
                    Style = "String"
                END
            /* create a new column, using either a custom column name or the default from the English file */
            Fieldnames.i = "F" || I
            Fieldid.i = Vrmethod(Contname, "AddField", Style, Getcolumnname(98+I, Conttype, I), Fieldnames.i)
        END
        Fieldnames.10 = "Order"
        Fieldid.10 = Vrmethod(Contname, "AddField", "String", "Order", Fieldnames.10)

        Fieldnames.0 = 10
        Fieldid.0 = 10
        Initinprogress = 1
    END
        ELSE DO
            /* remove old records from container */
            DO FOREVER
                Rec = Vrget( Contname, "LastRecord" )
                IF Rec = "" THEN DO
                    Ok = Vrset( Contname, "Visible", 1 )
                    LEAVE
                END
                Ok = Vrmethod( Contname, "DBDelete", Rec )
            END
            DROP Rec
        END

    CALL Setcolumnvisibility(Conttype)

    DROP J Value Colord

    /* populate container with INI records */
    I = 0
    IF Iniloaded = 1 THEN DO
        Items.0 = 0
        DO I = 1 TO Krgetreccount(Conttype)
            Items.i = Krgetrec(Conttype,,
                I,,
                Getorder(Conttype),,
                Fieldid.1,,
                Fieldid.2,,
                Fieldid.3,,
                Fieldid.4,,
                Fieldid.5,,
                Fieldid.6,,
                Fieldid.7,,
                Fieldid.8,,
                Fieldid.9,,
                Fieldid.10)
        END
        Items.0 = I-1
        Ok = Vrmethod( Contname, "AddRecordList", , "Last", "Items.")
        Ok = Sortarrange(Conttype)
        DROP Ok I Items
    END

    Ok = Vrset(Contname, "Caption", Getpagename(240 + Conttype, Conttype))

    DROP Ok Initinprogress Contname Conttype
RETURN 1

/*:VRX         GetColumnName
*/
GetColumnName: 
    Value = Krgetcolumnname(ARG(2), ARG(3))
    IF Value = "" THEN DO
        Value = Vlsmsg(ARG(1))
    END
RETURN Value

/*:VRX         GetFieldName
*/
Getfieldname: PROCEDURE
    Page = ARG(1)
    Flag = ARG(2)
    DO I = 1 TO 9
        Colstr = Krgetcolumnenable(Page, I)
        PARSE VAR Colstr E "�" F "�" H "�" A
        IF Flag = F THEN DO
            RETURN "F" || I
        END
    END
RETURN 0

/*:VRX         GetOrder
*/
Getorder: PROCEDURE
    Pg = ARG(1)
    Order = ""
    Strg = Krgetpageordenb(Pg)
    DO I = 1 TO 9
        Order = Order || SUBSTR(Strg, 4 + ((I - 1) * 4), 1)
    END
RETURN Order


/*:VRX         GetPageName
*/
GetPageName: 
    Value = Krgetpagename(ARG(2))
    IF Value = "" THEN DO
        Value = Vlsmsg(ARG(1))
    END
return Value

/*:VRX         Halt
*/
Halt:

exit

/*:VRX         NormalMouse
*/
NormalMouse: 
    CALL Vrset Vrwindow(), "Pointer", "<default>"/* show "Busy" mouse pointer */
return

/*:VRX         RestoreProps
*/
RestoreProps: 
    IF Vrgetini( Appname, "CustomFontCB", Ininame, "NOCLOSE" ) <> "1" THEN do
        RETURN
    end

    CALL Waitmouse

    do x = 1 to Contnames.0
        Obj = Contnames.x||"Container"
        Value = Vrgetini( Appname, Obj, Ininame, "NOCLOSE" )
        if value <> "" then do
            PARSE VAR VALUE Font "�" Fore "�" Back
            Ok = Vrset(Obj, "font", Font)
            Ok = Vrset(Obj, "forecolor", Fore)
            Ok = Vrset(Obj, "backcolor", Back)
        end
    end
    CALL Normalmouse
    RETURN    

    /* this stuff is obsolete and slow */

    Ok = Vrmethod( Vrget(Vrwindow(), "name"), "ListChildren", "child." )

    Lastchild=Child.0+1
    Child.lastchild= Vrget(Vrwindow(), "name")
    Child.0=Lastchild
    Initstring=""
    DO X=1 TO Child.0
        IF Vrmethod( "Application", "SupportsProperty", Child.x , "font" ) = 1 THEN DO
            IF Vrmethod( "Application", "SupportsProperty", Child.x , "forecolor" ) = 1 THEN DO
                IF Vrmethod( "Application", "SupportsProperty", Child.x , "backcolor" ) = 1 THEN DO
                    Value = Vrgetini( Appname, Vrget(Child.x, Name), Ininame, "NOCLOSE" )
                    IF Value <> '' THEN DO
                        IF Vrget( Child.x, "ClassName" ) <> "PictureBox" THEN DO
                            PARSE VAR VALUE Font "�" Fore "�" Back
                            Ok = Vrset(Child.x, "font", Font)
                            /*
                            Ok = Vrset(Child.x, "forecolor", Fore)
                            Ok = Vrset(Child.x, "backcolor", Back)
                            */
                        END
                    END
                END
            END
        END
    END
    CALL Normalmouse

return

/*:VRX         SetColumnVisibility
*/
SetColumnVisibility: PROCEDURE EXPOSE Contnames. Showpw
    Conttype = ARG(1)
    Contname = Contnames.conttype || "Container"
    Ok = Vrset(Contname, "Visible", 0 )

    /* get the list of fields from the current container */
    Ok = Vrmethod( Contname, "GetFieldList", "Fields." )
    DO J = 1 TO 9
        Colstr = Krgetcolumnenable(Conttype, J)
        PARSE VAR Colstr Enb "�" Flag "�" Hint
        Ok = Vrmethod( Contname, "SetFieldAttr", Fields.j, "Visible", Enb )
    END

    IF Showpw = 0 THEN DO
        /* override password column visibility if showpw is off */
        /* but don't turn it on if it was off in the setup settings */
        Ok = Vrmethod( Contname, "SetFieldAttr", Getfieldname(Conttype, "P"), "Visible", 0)
    END

    /* hide the order field */
    Ok = Vrmethod( Contname, "SetFieldAttr", Fields.10, "Visible", 0 )

    /* turn on container visiblity */
    Ok = Vrset(Contname, "Visible", 1 )
RETURN
/*:VRX         SortArrange
*/
SortArrange: 
    Cont = ARG(1)
    Ok = Vrset(Contnames.cont || "Container", "Visible", 0)
    Si = Vrgetini( Appname, "SORT" || Cont, Ininame )
    View = Vrgetini( Appname, "VIEW" || Cont, Ininame )
    Mini = Vrgetini( Appname, "MINI" || Cont, Ininame )

    IF View = "" THEN DO
        View = 1
    END
    IF Mini = "" THEN DO
        Mini = 1
    END
    IF Si = "" THEN DO
        Si = 1
    END

    /* remap slider ticks to correct container column # */
    Mappedsi = Tickmap.si

    Ok = Configwincontrols(Contnames.cont, Getfieldname(Cont, Tickmap.si), View, Mini, Si)
    Ok = Vrset(Contnames.cont || "Container", "Visible", 1)
    DROP View Si Mini

RETURN Ok


/*:VRX         WaitMouse
*/
WaitMouse: 
    CALL Vrset Vrwindow(), "Pointer", "Wait"/* show "Busy" mouse pointer */
return

