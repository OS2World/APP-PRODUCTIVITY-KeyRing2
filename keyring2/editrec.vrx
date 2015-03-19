/*:VRX         Main
*/
/*  Main ~nokeywords~
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
        SIGNAL _VRELeaveMain
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
        SIGNAL __VRLSDone
    IF __vrlswait \= 1 THEN
        SIGNAL __VRLSDone
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

/*:VRX         AddBackslash
*/
Addbackslash:
    Strg = ARG(1)
    IF Strg <> "" THEN DO
        IF SUBSTR(Strg, LENGTH(Strg)) <> '\' THEN
            Strg = Strg || '\'
    END
RETURN Strg

/*:VRX         AdjustDateSpinners
*/
AdjustDateSpinners: PROCEDURE
    NumDays = ARG(1)    
    D = VRGet( "ExpDaysSpinner", "Value" )
    M = VRGet( "ExpMonthsSpinner", "Value" )
    Y = VRGet( "ExpYearsSpinner", "Value" )

    Julian = KRDMY2Julian(D, M, Y) + NumDays
    if Julian < KRGetTodayJulian() then do
        Julian = KRGetTodayJulian()
    end

    d = KRJulian2DMY(Julian, 1)
    m = KRJulian2DMY(Julian, 2)
    y = KRJulian2DMY(Julian, 3)

    ok = VRSet( "ExpDaysSpinner", "Value", D)
    ok = VRSet( "ExpMonthsSpinner", "Value", M)
    ok = VRSet( "ExpYearsSpinner", "Value", Y)

return

/*:VRX         Alpha_Click
*/
Alpha_click:
    Passmode = 1
    Ok = Vrset( "Alpha", "Checked", 1 )
    Ok = Vrset( "Numeric", "Checked", 0 )
    Ok = Vrset( "AlphaNumeric", "Checked", 0 )
    Ok = Vrset( "AlphaNumericPunct", "Checked", 0 )

RETURN

/*:VRX         AlphaNumeric_Click
*/
Alphanumeric_click:
    Passmode = 3
    Ok = Vrset( "Alpha", "Checked", 0 )
    Ok = Vrset( "Numeric", "Checked", 0 )
    Ok = Vrset( "AlphaNumeric", "Checked", 1 )
    Ok = Vrset( "AlphaNumericPunct", "Checked", 0 )
RETURN

/*:VRX         AlphaNumericPunct_Click
*/
Alphanumericpunct_click:
    Passmode = 4
    Ok = Vrset( "Alpha", "Checked", 0 )
    Ok = Vrset( "Numeric", "Checked", 0 )
    Ok = Vrset( "AlphaNumeric", "Checked", 0 )
    Ok = Vrset( "AlphaNumericPunct", "Checked", 1 )
RETURN

/*:VRX         EditRec_Close
*/
Editrec_close:
    CALL Quit
RETURN

/*:VRX         EditRec_Help
*/
Editrec_help:
    CALL INFHelp(Vrinfo("Source"))

RETURN





/*:VRX         EditRec_LangException
*/
EditRec_LangException: 

return

/*:VRX         EditRec_LangInit
*/
EditRec_LangInit:

    /* ------------------------------------------------ */
    /* Language internationalization code autogenerated */
    /* by VXNation v1.0, Copyright 1999, IDK, Inc.      */
    /*          http://www.idk-inc.com                  */
    /* Autogenerated: 03/06/2000 19:20:22             */
    /* ------------------------------------------------ */
    /* Warning! This code gets overwritten by VXNation! */
    /* Do not make modifications here!                  */
    /* ------------------------------------------------ */

    /* Edit Secret */
    Ok = VRSet("EditRec", "WindowListTitle", VLSMsg(136))

    /* Edit Secret Information */
    Ok = VRSet("EditRec", "Caption", VLSMsg(137))

    /* ~Save */
    Ok = VRSet("SaveButton", "Caption", VLSMsg(15))

    /* Save your edits and return to main program */
    Ok = VRSet("SaveButton", "HintText", VLSMsg(139))

    /* Quit */
    Ok = VRSet("QuitButton", "Caption", VLSMsg(140))

    /* Abort your changes */
    Ok = VRSet("QuitButton", "HintText", VLSMsg(141))

    /* Password expiration date */
    Ok = VRSet("ExpDaysSpinner", "HintText", VLSMsg(293))
    Ok = VRSet("ExpMonthsSpinner", "HintText", VLSMsg(294))
    Ok = VRSet("ExpYearsSpinner", "HintText", VLSMsg(393))

    /* Description of this secret info */
    Ok = VRSet("F1", "HintText", VLSMsg(142))

    /* Your name, alias, login name, Etc */
    Ok = VRSet("F2", "HintText", VLSMsg(144))

    /* Serial number, combination, PIN number, Etc for this secret */
    Ok = VRSet("F4", "HintText", VLSMsg(146))

    /* Password for this application, web page, login, Etc. */
    Ok = VRSet("F3", "HintText", VLSMsg(148))

    /* URL for this secret */
    Ok = VRSet("F5", "HintText", VLSMsg(151))

    /* Note for this secret */
    Ok = VRSet("F6", "HintText", VLSMsg(152))

    /* Days to password expriation (warning only) */
    Ok = VRSet("ExpDaysSpinner", "HintText", VLSMsg(293))
    Ok = VRSet("ExpMonthsSpinner", "HintText", VLSMsg(294))
    Ok = VRSet("ExpYearsSpinner", "HintText", VLSMsg(392))


    do index = 1 to 31
        SpinDayList.index = index
    end

    SpinDayList.0 = 31

    do index = 1 to 12
        SpinMonthList.index = index
    end

    SpinMonthList.0 = 12;

    do index = 2000 to 2099
        i = index - 1999
        SpinYearList.i = index
    end

    SpinYearList.0 = 100
    
    ok = VRMethod( "ExpDaysSpinner", "SetStringList", "SpinDayList." )
    ok = VRMethod( "ExpMonthsSpinner", "SetStringList", "SpinMonthList." )
    ok = VRMethod( "ExpYearsSpinner", "SetStringList", "SpinYearList." )
    drop spindaylist.
    drop spinmonthlist.
    drop spinyearlist.
    drop i

    /* Current Expiration Date */
    Ok = VRSet("CurrentExpDateFieldCaption", "Caption", VLSMsg(297))

    /* I'm a logo! */
    Ok = VRSet("Pict_8", "HintText", VLSMsg(156))

    /* KeyRing/2 */
    Ok = VRSet("TT_2", "Caption", VLSMsg(2))

    /* Drop an icon here, or right click for options */
    Ok = VRSet("IconField", "HintText", VLSMsg(157))

    /* EditRecMenu */
    Ok = VRSet("EditRecMenu", "Caption", VLSMsg(158))

    /* Suggest Password */
    Ok = VRSet("SuggestPW", "Caption", VLSMsg(159))

    /* - */
    Ok = VRSet("MItem_6", "Caption", VLSMsg(24))

    /* Lower Case */
    Ok = VRSet("LowerCase", "Caption", VLSMsg(160))

    /* Upper Case */
    Ok = VRSet("Uppercase", "Caption", VLSMsg(161))

    /* Mixed Case */
    Ok = VRSet("MixedCase", "Caption", VLSMsg(162))

    /* - */
    Ok = VRSet("MItem_10", "Caption", VLSMsg(24))

    /* Alpha */
    Ok = VRSet("Alpha", "Caption", VLSMsg(163))

    /* Numeric */
    Ok = VRSet("Numeric", "Caption", VLSMsg(164))

    /* Alpha-Numeric */
    Ok = VRSet("AlphaNumeric", "Caption", VLSMsg(165))

    /* Alphanumeric + Punctuation */
    Ok = VRSet("AlphaNumericPunct", "Caption", VLSMsg(166))

    /* IconMenu */
    Ok = VRSet("IconMenu", "Caption", VLSMsg(167))

    /* Open Icon File */
    Ok = VRSet("OpenIconFileItem", "Caption", VLSMsg(168))

    /* Select Internal Icon */
    Ok = VRSet("InternalIconItem", "Caption", VLSMsg(169))

    call EditRec_LangException
    DROP Ok

RETURN

/*:VRX         ExpDaysSpinner_Change
*/
ExpDaysSpinner_Change: 
    CALL ExpSpinner_Change
return

/*:VRX         ExpSpinner_Change
*/
ExpSpinner_Change: 
    Days = Vrget( "ExpDaysSpinner", "Value" )
    Months = Vrget( "ExpMonthsSpinner", "Value" )
    Years = Vrget( "ExpYearsSpinner", "Value" )

    Expdate = KRDMY2Date(Days, Months, Years)

    Ok = Vrset( "CurrentExpDateField", "Value", Expdate )
return

/*:VRX         ExpYearsSpinner_Change
*/
ExpYearsSpinner_Change: 
    CALL ExpSpinner_Change
return

/*:VRX         F1_ContextMenu
*/
F1_contextmenu:
    IF Passwordfield = "F1" THEN DO
        CALL Vrmethod "EditRecMenu", "Popup"
    END

RETURN

/*:VRX         F2_ContextMenu
*/
F2_contextmenu:
    IF Passwordfield = "F2" THEN DO
        CALL Vrmethod "EditRecMenu", "Popup"
    END

RETURN

/*:VRX         F3_ContextMenu
*/
F3_contextmenu:
    IF Passwordfield = "F3" THEN DO
        CALL Vrmethod "EditRecMenu", "Popup"
    END
RETURN

/*:VRX         F4_ContextMenu
*/
F4_contextmenu:
    IF Passwordfield = "F4" THEN DO
        CALL Vrmethod "EditRecMenu", "Popup"
    END

RETURN

/*:VRX         F5_ContextMenu
*/
F5_contextmenu:
    IF Passwordfield = "F5" THEN DO
        CALL Vrmethod "EditRecMenu", "Popup"
    END

RETURN

/*:VRX         F6_ContextMenu
*/
F6_contextmenu:
    IF Passwordfield = "F6" THEN DO
        CALL Vrmethod "EditRecMenu", "Popup"
    END

RETURN

/*:VRX         Fini
*/
Fini:
    Ok = Vrsetini( Appname, "PWCASE", Passcase, Ininame )
    Ok = Vrsetini( Appname, "PWMODE", Passmode, Ininame )

    Window = Vrwindow()
    CALL Vrset Window, "Visible", 0
    DROP Window
RETURN Editresult
/*:VRX         FixDateSpinners
*/
FixDateSpinners: 
    say "fix spin"

    D = VRGet( "ExpDaysSpinner", "Value" )
    M = VRGet( "ExpMonthsSpinner", "Value" )
    Y = VRGet( "ExpYearsSpinner", "Value" )

    Julian = KRDMY2Julian(D, M, Y)
    if Julian < KRGetTodayJulian() then do
        Julian = KRGetTodayJulian()
    end

    d = KRJulian2DMY(Julian, 1)
    m = KRJulian2DMY(Julian, 2)
    y = KRJulian2DMY(Julian, 3)

    ok = VRSet( "ExpDaysSpinner", "Value", D)
    ok = VRSet( "ExpMonthsSpinner", "Value", M)
    ok = VRSet( "ExpYearsSpinner", "Value", Y)

return

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
            PARSE VAR Strg Enb "�" Flg "�" Hint "�" Abbrev
            drop abbrev
            RETURN Hint
        END
RETURN

/*:VRX         Halt
*/
Halt:
    SIGNAL _VREHalt
RETURN

/*:VRX         IconContainer_DoubleClick
*/
Iconcontainer_doubleclick:

RETURN

/*:VRX         IconField_Click
*/
Iconfield_click:
    CALL IconField_ContextMenu
RETURN

/*:VRX         IconField_ContextMenu
*/
Iconfield_contextmenu:
    Ok = Vrmethod( "IconMenu", "Popup", , , "OpenIconFileItem", "" )
RETURN


/*:VRX         IconField_DragDrop
*/
Iconfield_dragdrop:
    Record = Vrinfo( "Record" )
    Srcfile = Vrinfo( "SourceFile" )
    Container = Vrinfo("SourceObject")
    IF Srcfile = "" THEN DO
        Value = Vrmethod( Container, "GetRecordAttr", Record, "Icon" )
        Ok = Vrset( "IconField", "PicturePath", Value )
    END
        ELSE DO
            Ok = Vrset( "IconField", "PicturePath", Srcfile )
        END
RETURN

/*:VRX         IconMenu_Click
*/
Iconmenu_click:

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
    Ok = Vrredirectstdio("On", "keyring2.err")

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
    CALL EditRec_LangInit

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

    CALL SetDMY    

    /* set window location */
    Value = Vrgetini( Appname, "EDITRECTOP", Ininame )
    IF Value = "" THEN do
        Value = 1156
    end
    Editrectop = Value

    Value = Vrgetini( Appname, "EDITRECLEFT", Ininame )
    IF Value = "" THEN do
        Value =434
    end
    Editrecleft = Value

    Value = Vrgetini( Appname, "EDITRECHYT", Ininame )
    IF Value = "" THEN do
        Value = 7480
    end
    Editrechyt = Value

    Value = Vrgetini( Appname, "EDITRECWID", Ininame )
    IF Value = "" THEN do
        Value = 5974
    end
    Editrecwidth = Value

    Ok = Vrset( "EDITREC", "Top", Editrectop )
    Ok = Vrset( "EDITREC", "Left", Editrecleft )
    Ok = Vrset( "EDITREC", "Height", Editrechyt )
    Ok = Vrset( "EDITREC", "Width", Editrecwidth )

    Window = Vrwindow()
    CALL Vrset Window, "Visible", 1
    CALL Vrmethod Window, "Activate"
    DROP Window

    Passmode = Vrgetini( "KR2", "PWMODE", "KR2.INI" )
    IF Passmode = "" THEN do
        Passmode = 3
    end

    SELECT
        WHEN Passmode = 1 THEN DO
            CALL LowerCase_Click
        END
        WHEN Passmode = 2 THEN DO
            CALL UpperCase_Click
        END
        WHEN Passmode = 3 THEN DO
            CALL MixedCase_Click
        END
        OTHERWISE DO 
            CALL MixedCase_Click
            Passmode = 3
        END
    END

    Passmode = Vrgetini( Appname, "PWCASE", Ininame )

    IF Passcase = "" THEN do
        Passcase = 3
    end

    SELECT
    
        WHEN Passcase = 1 THEN DO
            CALL Alpha_Click
        END
        WHEN Passcase = 2 THEN DO
            CALL Numeric_Click
        END
        WHEN Passcase = 3 THEN DO
            CALL AlphaNumeric_Click
        END
        WHEN Passcase = 4 THEN DO
            CALL AlphaNumericPunct_Click
        END
        otherwise do
            CALL AlphaNumeric_Click
            Passcase = 3
        end
    END
    
    Editresult = ""
RETURN

/*:VRX         InternalIconItem_Click
*/
Internaliconitem_click:
    Iconselthreadid = Vrmethod( "Application", "StartThread", "IconSel", Appname, Ininame )
RETURN

/*:VRX         LowerCase_Click
*/
Lowercase_click:
    Passcase = 1
    Ok = Vrset( "LowerCase", "Checked", 1 )
    Ok = Vrset( "UpperCase", "Checked", 0 )
    Ok = Vrset( "MixedCase", "Checked", 0 )
RETURN

/*:VRX         Minus30Button_Click
*/
Minus30Button_Click: 
    CALL AdjustDateSpinners(-30)
return

/*:VRX         MixedCase_Click
*/
Mixedcase_click:
    Passcase = 3
    Ok = Vrset( "LowerCase", "Checked", 0 )
    Ok = Vrset( "UpperCase", "Checked", 0 )
    Ok = Vrset( "MixedCase", "Checked", 1 )
RETURN

/*:VRX         NoExpireCheckbox_Click
*/
NoExpireCheckbox_Click: 
   Enable = \ VRGet( "NoExpireCheckbox", "Set" )
    
   ok = VRSet( "CurrentExpDateFieldCaption", "Visible", Enable )
   ok = VRSet( "ExpDaysSpinner", "Enabled", Enable )
   ok = VRSet( "ExpMonthsSpinner", "Enabled", Enable )
   ok = VRSet( "ExpYearsSpinner", "Enabled", Enable )
   ok = VRSet( "TodayButton", "Enabled", Enable)
   ok = VRSet( "Plus30Button", "Enabled", Enable)
   ok = VRSet( "Minus30Button", "Enabled", Enable)

   if \ Enable then do 
       ok = VRSet( "ExpDaysSpinner", "Value", 1)
       ok = VRSet( "ExpMonthsSpinner", "Value", 1)
       ok = VRSet( "ExpYearsSpinner", "Value", 2099)
   end
Return


/*:VRX         Numeric_Click
*/
Numeric_click:
    Passmode = 2
    Ok = Vrset( "Alpha", "Checked", 0 )
    Ok = Vrset( "Numeric", "Checked", 1 )
    Ok = Vrset( "AlphaNumeric", "Checked", 0 )
    Ok = Vrset( "AlphaNumericPunct", "Checked", 0 )
RETURN

/*:VRX         OpenIconFileItem_Click
*/
Openiconfileitem_click:
    Filename = Vrfiledialog( Vrwindow(), Vlsmsg(170) /* Select an Icon for this secret */, "Open", AddBackSlash(Vrgetini( Appname, "IconPath", Ininame )) || "*.ico", , , )

    Ok = Vrsetini( Appname, "IconPath", Vrparsefilepath(Filename, "DP" ), Ininame )
    IF Filename = "" THEN DO
        Filename = "$3"
	END
    Ok = Vrset( "IconField", "PicturePath", Filename )
RETURN

/*:VRX         Plus30Button_Click
*/
Plus30Button_Click: 
    CALL AdjustDateSpinners(30)
return

/*:VRX         Quit
*/
Quit:
    Ok = Vrsetini( Appname, "EDITRECTOP", Vrget("EDITREC", "Top" ), Ininame)
    Ok = Vrsetini( Appname, "EDITRECLEFT", Vrget("EDITREC", "Left" ), Ininame)
    Ok = Vrsetini( Appname, "EDITRECHYT", Vrget("EDITREC", "Height" ), Ininame)
    Ok = Vrsetini( Appname, "EDITRECWID", Vrget("EDITREC", "Width" ), Ininame)

    Window = Vrwindow()
    CALL Vrset Window, "Shutdown", 1
    DROP Window
RETURN

/*:VRX         QuitButton_Click
*/
Quitbutton_click:
    Editresult = ""
    CALL EditRec_Close
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
        Value = Vrgetini(Appname, Vrget(Child.x, Name), Ininame, "NOCLOSE" )
        PARSE VAR VALUE Font "�" Fore "�" Back
        Ok = Vrset(Child.x, "font", Font)
        Ok = Vrset(Child.x, "forecolor", Fore)
        Ok = Vrset(Child.x, "backcolor", Back)
    END

RETURN

/*:VRX         SaveButton_Click
*/
Savebutton_click: PROCEDURE EXPOSE Initargs. Editresult AppName INiName DirtyFlag
    call AdjustDateSpinners(0) /* just fix bad dates */
    call UpdateExpireDate
    Spinval = Vrget( "ExpDaysSpinner", "Value" )
    Expdate = ""
    IF Spinval <> Vlsmsg(171) THEN DO                       /* No Exp */
        Expdate = Krcalcdate("", Spinval)
    END
    Ok = Vrset(Initargs.1, "Visible", 0)

    /* set the icon view fields of the record */
    Ok = Vrmethod( Initargs.1, "SetRecordAttr", Initargs.2, "Icon", Vrget( "IconField", "PicturePath" ))

    /* Update the caption using the current description field string */
    Value = Vrget(Geteditfieldname("D"), "Value")
    Value = StuffCR(Value)
    Ok = Vrmethod( Initargs.1, "SetRecordAttr", Initargs.2, "Caption", Value)

    /* get list of field handles for current container */
    Ok = Vrmethod(Initargs.1, "GetFieldList", "Fields." )

    /* now set the rest of the fields */
    Ok = Vrmethod( Initargs.1, "GetFieldData", Initargs.2, "Fieldvals." )
    order = Fieldvals.10

    DO J = 1 TO 9
        Tf = Geteditfieldname(SUBSTR(Order, J, 1))/* get the name of the Nth field */
        SELECT
            WHEN Tf = "LastUpdateField" THEN DO/* handle special case */
                Ok = Vrmethod( Initargs.1, "SetFieldData", Initargs.2, Fields.j, Krgettime())
            END
            WHEN Tf = "IconField" THEN DO      /* handle special case */
                Ok = Vrmethod( Initargs.1, "SetFieldData", Initargs.2, Fields.j, Vrget( "IconField", "PicturePath" ))
            END
            OTHERWISE DO/* handle all the normal user-editable text fields */
                Ok = Vrmethod( Initargs.1, "SetFieldData", Initargs.2, Fields.j, Vrget(Tf, "Value" ))
            END
        END
    END
    Ok = Vrset(Initargs.1, "Visible", 1)

    Editresult = 1
    DirtyFlag = 1
    CALL EditRec_Close
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
                    Initstrg = Vrget(Child.x, "font") || "�" Vrget(Child.x, "forecolor") || "�" Vrget(Child.x, "backcolor")
                    Ok = Vrsetini( "KR2", Vrget(Child.x, "Name"), Initstrg, "KR2.INI", "NOCLOSE" )
                END
            END
        END
    END
RETURN

/*:VRX         SetDMY
*/
SetDMY: 
    ExpDate = VRGet( "CurrentExpDateField", "Value" )

    ok = VRSet( "ExpDaysSpinner", "Value", KRDate2DMY(ExpDate, 1) )
    ok = VRSet( "ExpMonthsSpinner", "Value", KRDate2DMY(ExpDate, 2) )
    ok = VRSet( "ExpYearsSpinner", "Value", KRDate2DMY(ExpDate, 3) )
return

/*:VRX         SetHints
*/
Sethints:
    Ctr = 1
    DO I = 1 TO 9
        SELECT
            WHEN I = Iconindx THEN DO
                Ok = Vrset("IconField", "HintText", Vlsmsg(157))
            END
            WHEN I = Lastindx THEN DO
                /* just skip last update field */
            END
            WHEN I = Expindx THEN DO
                Ok = Vrset("CurrentExpDateField", "HintText", Vlsmsg(154))
            END
            OTHERWISE DO
                Ok = Vrset("F" || Ctr, "HintText", Gethinttext(SUBSTR(Order, I, 1)))
                Ctr = Ctr + 1
            END
        END
    END
RETURN

/*:VRX         StuffCR
*/
StuffCR: 
    Strg = ARG(1)
    p = Pos( "^", Strg)
    
    do while p > 0
        Strg = Overlay(D2C(10), Strg, p)
        p = Pos( "^", Strg)
    end

    drop p
return Strg
    
    

/*:VRX         SuggestPW_Click
*/
Suggestpw_click:
    Id = 1
    IF Vrget(Passwordfield, "Value") <> "" THEN DO
        Buttons.1 = Vlsmsg(172)                               /* ~Yes */
        Buttons.2 = Vlsmsg(173)                                /* ~No */
        Buttons.0 = 2
        Id = Vrmessage( Vrwindow(), Vlsmsg(174) /* Are you sure you want to overwrite the existing password? */, Vlsmsg(120) /* Warning! */, "Warning", "Buttons.", 2, 2 )
        DROP Buttons
    END
    IF Id = 1 THEN
        Ok = Vrset(Passwordfield, "Value", Krmakepassword( Passmode, Passcase) )
    DROP Id Ok
RETURN
/*:VRX         TodayButton_Click
*/
TodayButton_Click: 
    ok = VRSet( "ExpDaysSpinner", "Value", KRGetToday(1))
    ok = VRSet( "ExpMonthsSpinner", "Value", KRGetToday(2))
    ok = VRSet( "ExpYearsSpinner", "Value", KRGetToday(3))
return

/*:VRX         UpdateExpireDate
*/
UpdateExpireDate: 
    D = VRGet( "ExpDaysSpinner", "Value" )
    M = VRGet( "ExpMonthsSpinner", "Value" )
    Y = VRGet( "ExpYearsSpinner", "Value" )
    Value = KRDMY2Date(D, M, Y)
    ok = VRSet( "CurrentExpDateField", "Value", Value )
return

/*:VRX         Uppercase_Click
*/
Uppercase_click:
    Passcase = 2
    Ok = Vrset( "LowerCase", "Checked", 0 )
    Ok = Vrset( "UpperCase", "Checked", 1 )
    Ok = Vrset( "MixedCase", "Checked", 0 )
RETURN
