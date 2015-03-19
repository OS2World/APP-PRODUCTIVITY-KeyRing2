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
    window = VRWindow()
    call VRMethod window, "CenterWindow"
    Ok = VRRedirectStdIO('on', 'junk.tmp')
    call VRSet window, "Visible", 1
    call VRMethod window, "Activate"
    drop window
return

/*:VRX         OriginalButton_Click
*/
OriginalButton_Click: 
    PDButs.0 = 3 
    PDButs.1 = "~Accept"
    PDButs.2 = "~Job Properties"
    PDButs.3 = "Cancel"
    PrnName = VRMethod( "PRT_1", "PrinterDialog", "Select a printer", "PDButs.");
    if PrnName = '' then
        return

    ok = VRMethod( "PRT_1", "SetMargins", 10, 10, 20, 25, 0, 0, "<default>", "<default>" );
    ok = VRMethod( "PRT_1", "SetHeaderMode", 1, "Helv", 10, 8, 26, 1, "<default>", "<default>", "<default>" );
    ok = VRMethod( "PRT_1", "SetHeader", 3, "$c|", "", "$cIDK, Inc.");
    ok = VRMethod( "PRT_1", "SetHeaderLineFont", 1, "Helv", 15);
    ok = VRMethod( "PRT_1", "SetHeaderLineFont", 3, "Helv", 8);
    ok = VRMethod( "PRT_1", "SetFooter", "Helv", 10, 8, 14, "$@ $?$rPage $#", "<default>", "<default>", "<default>" );
    ok = VRMethod( "PRT_1", "OpenPrintJob", "KeyRing/2 Records");
    rcy = VRMethod( "PRT_1", "PrintLine",facename, 12,'');

    rcy = VRMethod( "PRT_1", "PrintBitMap", "$101", 20, 120, 120, 220, 28, ,'Fig 1. - A bitmap from exe resource');
    rcy = VRMethod( "PRT_1", "PrintBitMap", ".\graphics\crink-l.bmp", 30, 20, 110, 95, 56, ,'Fig 2. - A bitmap from a file');

            rcy = VRMethod( "PRT_1", "NewPage");

            hmod = VRMethod( "PRT_1", "LoadResMod", "krini");
            rcy = VRMethod( "PRT_1", "PrintBitMap", hmod || "$4", 20, 120, 120, 220, 28, ,'Fig 3. - A bitmap from a DLL');

            rcy = VRMethod( "PRT_1", "NewPage");
            rcy = VRMethod( "PRT_1", "PrintCentered", "Helv", 10, 'This one has no title and no declared dimensions');
            rcy = VRMethod( "PRT_1", "Goto", 50, 100);
            rcy = VRMethod( "PRT_1", "PrintBitMap", ".\graphics\crink-l.bmp",,,,, 14);
            call VRMethod "PRT_1", "FreeResMod", hmod

    ok = VRMethod( "PRT_1", "ClosePrintJob" )

return

/*:VRX         Quit
*/
Quit:
    window = VRWindow()
    call VRSet window, "Shutdown", 1
    drop window
return

/*:VRX         QuitButton_Click
*/
QuitButton_Click: 
    Call Quit
return

/*:VRX         TableButton_Click
*/
TableButton_Click: 
    PDButs.0 = 3 
    PDButs.1 = "~Accept"
    PDButs.2 = "~Job Properties"
    PDButs.3 = "Cancel"
    PrnName = VRMethod( "PRT_1", "PrinterDialog", "Select a printer", "PDButs.");
    if PrnName = '' then
        return

    ok = VRMethod( "PRT_1", "SetMargins", 10, 10, 20, 25, 0, 0, "<default>", "<default>" );
    ok = VRMethod( "PRT_1", "SetHeaderMode", 1, "Helv", 10, 8, 26, 1, "<default>", "<default>", "<default>" );
    ok = VRMethod( "PRT_1", "SetHeader", 3, "$c|", "", "$cIDK, Inc.");
    ok = VRMethod( "PRT_1", "SetHeaderLineFont", 1, "Helv", 15);
    ok = VRMethod( "PRT_1", "SetHeaderLineFont", 3, "Helv", 8);
    ok = VRMethod( "PRT_1", "SetFooter", "Helv", 10, 8, 14, "$@ $?$rPage $#", "<default>", "<default>", "<default>" );
    ok = VRMethod( "PRT_1", "OpenPrintJob", "KeyRing/2 Records");
    rcy = VRMethod( "PRT_1", "PrintLine","Helv", 12,'');

    /***** Define the table ********************************/

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

    /***** Make 9 columns ***********************************/

    Cols.0.0 = 9
        
    Cols.1.1 = Trunc( (0.0686 * FormWidth)+0.5, "0" )
    Cols.1.2 = 'Icon'

    Cols.2.1 = Trunc( (0.097142 * FormWidth)+0.5, "0" )
    Cols.2.2 = '$cDesc'
    
    Cols.3.1 = Trunc( (0.097142 * FormWidth)+0.5, "0" )
    Cols.3.2 = '$cP/W'
    
    Cols.4.1 = Trunc( (0.097142 * FormWidth)+0.5, "0" )
    Cols.4.2 = '$cName'
    
    Cols.5.1 = Trunc( (0.097142 * FormWidth)+0.5, "0" )
    Cols.5.2 = '$cS/N'
    
    Cols.6.1 = Trunc( (0.097142 * FormWidth)+0.5, "0" )
    Cols.6.2 = '$cUpdate'

    Cols.7.1 = Trunc( (0.097142 * FormWidth)+0.5, "0" )
    Cols.7.2 = '$cExp'

    Cols.8.1 = Trunc( (0.2 * FormWidth)+0.5, "0" )
    Cols.8.2 = '$cURL'
    
    Cols.9.1 = Trunc( (0.15428 * FormWidth)+0.5, "0" )
    Cols.9.2 = '$cNote'
    
    names.0 = 18
    names.1 = 'g:\keyring2\graphics\bluedevl.ico'
    names.2 = 'BOX.BMP'
    names.3 = 'BRICK.BMP'
    names.4 = 'BUTTERFL.BMP'
    names.5 = 'COLUMNS.BMP'
    names.6 = 'DELFT.BMP'
    names.7 = 'FERNS.BMP'
    names.8 = 'FLAMINGO.BMP'
    names.9 = 'FLEUR.BMP'
    names.10 = 'LEAVES.BMP'
    names.11 = 'MAZE.BMP'
    names.12 = 'ORCHIDS.BMP'
    names.13 = 'OS2TILE.BMP'
    names.14 = 'SHELLS.BMP'
    names.15 = 'SUNFLOW.BMP'
    names.16 = 'SWIRLS.BMP'
    names.17 = 'TIEDYE.BMP'
    names.18 = 'ZIGZAG.BMP'
    
    rcy = VRMethod( "PRT_1", "DefineTable", "table.", "Cols.");
    
    /**** Start printing in the table **********************************/
    
    if rcy then do
        hmod = VRMethod( "PRT_1", "LoadResMod", "RESOURCE");
        say hmod
        hmodKR = VRMethod( "PRT_1", "LoadResMod", "KRINI");
        say hmodKR
        do i = 1 to 5
            Value = hmod || "$" || I
            rcy = VRMethod( "PRT_1", "StartRow");
            rcy = VRMethod( "PRT_1", "StartCol", 1)
            rcy = VRMethod( "PRT_1", "PrintBitMap", "g:\keyring2\graphics\cosmos1.ico",,,,,,,i);
            rcy = VRMethod( "PRT_1", "StartCol", 2)
            rcy = VRMethod( "PRT_1", "PrintBitMap", Value,,,,,,,I);
            say "rcy after hmod value = " || rcy
            say value
            /* rcy = VRMethod( "PRT_1", "PrintBitMap", hmod || "$" || I, , , , ,30,,"z"); */
            rcy = VRMethod( "PRT_1", "StartCol", 3)
            rcy = VRMethod( "PRT_1", "PrintBitMap", "g:\keyring2\graphics\cosmos1.ico",,,,,,,i);
            /* rcy = VRMethod( "PRT_1", "PrintBitMap", hmodKR || "$" || I, , , , ,30,,"z"); */
            rcy = VRMethod( "PRT_1", "StartCol", 4)
            rcy = VRMethod( "PRT_1", "PrintBitMap", "g:\keyring2\graphics\cosmos1.ico",,,,,,,i);
            /* rcy = VRMethod( "PRT_1", "PrintBitMap", "$1", , , , ,30,,"z"); */
            rcy = VRMethod( "PRT_1", "StartCol", 5)
            rcy = VRMethod( "PRT_1", "PrintBitMap", "g:\keyring2\graphics\cosmos1.ico",,,,,,,i);
            /* rcy = VRMethod( "PRT_1", "PrintBitMap", "#1", , , , ,30,,"z"); */
            rcy = VRMethod( "PRT_1", "StartCol", 6)
            rcy = VRMethod( "PRT_1", "PrintLeft", 'Helv', 8, "helloworld");
            rcy = VRMethod( "PRT_1", "StartCol", 7)
            rcy = VRMethod( "PRT_1", "PrintLeft", 'Helv', 8, "helloworld");
            rcy = VRMethod( "PRT_1", "StartCol", 8)
            rcy = VRMethod( "PRT_1", "PrintLeft", 'Helv', 8, "helloworld");
            rcy = VRMethod( "PRT_1", "StartCol", 9)
            rcy = VRMethod( "PRT_1", "PrintLeft", 'Helv', 8, "helloworld");
            rcy = VRMethod( "PRT_1", "EndRow");
        end
        rcy = VRMethod( "PRT_1", "EndTable");
        call VRMethod "PRT_1", "FreeResMod", hmod
    end    
    else
        rcy = VRMethod( "PRT_1", "PrintLine", 'Helvetica Bold', 14, 'ERROR - Failed to create the table...');
    
    ok = VRMethod( "PRT_1", "ClosePrintJob" )
return

/*:VRX         ThumnailButton_Click
*/
ThumnailButton_Click: 
    PDButs.0 = 3 
    PDButs.1 = "~Accept"
    PDButs.2 = "~Job Properties"
    PDButs.3 = "Cancel"
    PrnName = VRMethod( "PRT_1", "PrinterDialog", "Select a printer", "PDButs.");
    if PrnName = '' then
        return

    ok = VRMethod( "PRT_1", "SetMargins", 10, 10, 20, 25, 0, 0, "<default>", "<default>" );
    ok = VRMethod( "PRT_1", "SetHeaderMode", 1, "Helv", 10, 8, 26, 1, "<default>", "<default>", "<default>" );
    ok = VRMethod( "PRT_1", "SetHeader", 3, "$c|", "", "$cIDK, Inc.");
    ok = VRMethod( "PRT_1", "SetHeaderLineFont", 1, "Helv", 15);
    ok = VRMethod( "PRT_1", "SetHeaderLineFont", 3, "Helv", 8);
    ok = VRMethod( "PRT_1", "SetFooter", "Helv", 10, 8, 14, "$@ $?$rPage $#", "<default>", "<default>", "<default>" );
    ok = VRMethod( "PRT_1", "OpenPrintJob", "KeyRing/2 Records");
    rcy = VRMethod( "PRT_1", "PrintLine",facename, 12,'');
    hmod = VRMethod( "PRT_1", "LoadResMod", "krini");
    say hmod
    MinI = 1002 
    MaxI = 1130
    do i = MinI to MaxI
        Xt = ((I-MinI) // 15) * 12
        Yt = (((I-MinI) % 15) * 15) + 10
        say i || " (" || Xt || ", " || Yt || "),(" || Xt +10 || ", " || Yt + 10 || ")"
        rcy = VRMethod( "PRT_1", "PrintBitMap", hmod || "$" || I, xt, yt, xt+10, yt+10, 10, ,i); 
    end

    rcy = VRMethod( "PRT_1", "NewPage");
    call VRMethod "PRT_1", "FreeResMod", hmod
    ok = VRMethod( "PRT_1", "ClosePrintJob" )
return

/*:VRX         Window1_Close
*/
Window1_Close:
    call Quit
return

/*:VRX         WriteTable
*/
WriteTable: 
    
    /***** Initialise a table *******************************************/
    
    rcy = VRMethod( "PRT_1", "StartTable", 0, 28, 3, 10, 45, 50, 40);

    if rcy then do
        
        /***** Start printing a row *************************************/
        
        rcy = VRMethod( "PRT_1", "StartRow");

        /***** write to col 1 *******************************************/
        

        rcy = VRMethod( "PRT_1", "StartCol", 1);
        rcy = VRMethod( "PRT_1", "PrintRight", 'Helvetica', 10, 'This is some text in the first column. It is not very long,');
        
        /***** write to col 2 *******************************************/
        
        rcy = VRMethod( "PRT_1", "StartCol", 2);
        rcy = VRMethod( "PRT_1", "PrintJustified", 'Helvetica Bold', 10, 'This is some text in the second column. It is not very long,');
        rcy = VRMethod( "PRT_1", "PrintJustified",,,'This text has several lines and with a bit of luck should force a new page.');
        rcy = VRMethod( "PRT_1", "PrintJustified",,,'If it does then we have a test of a cell rolling over from one page to the next and we will not have to write any more.');
        
        /***** write to col 3 *******************************************/
        
        rcy = VRMethod( "PRT_1", "StartCol", 3);
        rcy = VRMethod( "PRT_1", "PrintCentered", 'Helvetica Bold', 14, 'This is some text in the third column. It is not very long,');
        
        /***** print out the row ****************************************/
        
        rcy = VRMethod( "PRT_1", "EndRow");
        
        /***** start the next row ***************************************/
        
        rcy = VRMethod( "PRT_1", "StartRow");
        
        /***** write to col 1 *******************************************/
        
        rcy = VRMethod( "PRT_1", "StartCol", 1);
        rcy = VRMethod( "PRT_1", "PrintRight", 'Times New Roman', 10, 'This is some text in the first column. It is not very long,');
        
        /***** write to col 2 *******************************************/
        
        rcy = VRMethod( "PRT_1", "StartCol", 2);
        rcy = VRMethod( "PRT_1", "PrintLeft", 'Helvetica Bold', 10, 'This is some text in the second column. It is not very long and should be left justified.');
        rcy = VRMethod( "PRT_1", "PrintCentered",,,'This text has several lines and with a bit of luck should be centred.');
        rcy = VRMethod( "PRT_1", "PrintJustified",,,'This text here was designed to be justified and should roll over several lines, of course the last line will be left aligned.');
        rcy = VRMethod( "PRT_1", "PrintRight",,,'This last bit of text should finally show all the styles in one cell as it is right aligned.');
        
        /***** write to col 3 *******************************************/
        
        rcy = VRMethod( "PRT_1", "StartCol", 3);
        rcy = VRMethod( "PRT_1", "PrintJustified", 'Times New Roman', 8, 'This is some text in the third column. It is not very long,');
        
        /***** print out the row ****************************************/
        
        rcy = VRMethod( "PRT_1", "EndRow");
        
        /***** Terminate the table **************************************/
        
        rcy = VRMethod( "PRT_1", "EndTable");

    end
    else
        rcy = VRMethod( "PRT_1", "PrintLeft", 'Helvetica Bold', 14, 'ERROR - Failed to create the table...');


return

/*:VRX         WriteTable2
*/
WriteTable2: 


/***** Define the table ********************************/

table.0 = 11
table.1 = 0
table.2 = 28
table.3 = 1
table.4 = 0
table.5 = 28
table.6 = 1
table.7 = 12
table.8 = 'Helvetica Bold'
table.9 = 10
table.10 = 15
table.11 = 15

/***** Make 3 columns ***********************************/

Cols.0.0 = 3

Cols.1.1 = 25
Cols.1.2 = 'Index'

Cols.2.1 = 50
Cols.2.2 = '$cImage'

Cols.3.1 = 70
Cols.3.2 = '$rRes Number'

names.0 = 18
names.1 = 'g:\keyring2\graphics\bluedevl.ico'
names.2 = 'BOX.BMP'
names.3 = 'BRICK.BMP'
names.4 = 'BUTTERFL.BMP'
names.5 = 'COLUMNS.BMP'
names.6 = 'DELFT.BMP'
names.7 = 'FERNS.BMP'
names.8 = 'FLAMINGO.BMP'
names.9 = 'FLEUR.BMP'
names.10 = 'LEAVES.BMP'
names.11 = 'MAZE.BMP'
names.12 = 'ORCHIDS.BMP'
names.13 = 'OS2TILE.BMP'
names.14 = 'SHELLS.BMP'
names.15 = 'SUNFLOW.BMP'
names.16 = 'SWIRLS.BMP'
names.17 = 'TIEDYE.BMP'
names.18 = 'ZIGZAG.BMP'

rcy = VRMethod( "PRT_1", "DefineTable", "table.", "Cols.");

/**** Start printing in the table **********************************/

if rcy then do
    hmod = VRMethod( "PRT_1", "LoadResMod", "RESOURCE");
    do i = 1 to 18
        rcy = VRMethod( "PRT_1", "StartRow");
        rcy = VRMethod( "PRT_1", "StartCol", 1)
        rcy = VRMethod( "PRT_1", "PrintLeft", 'Helvetica Bold', 10, i);
        rcy = VRMethod( "PRT_1", "StartCol", 2)
        resnum = 100 + i;
        if i = 1 then do
            rcy = VRMethod( "PRT_1", "PrintBitMap", Names.I,,,,,,,names.i);
        end
        else do
            rcy = VRMethod( "PRT_1", "PrintBitMap", hmod || '$' || resnum,,,,,,,names.i);
        end
        rcy = VRMethod( "PRT_1", "StartCol", 3)
        rcy = VRMethod( "PRT_1", "PrintRight", 'Helvetica Bold', 10, resnum);
        rcy = VRMethod( "PRT_1", "EndRow");
    end
    rcy = VRMethod( "PRT_1", "EndTable");
    call VRMethod "PRT_1", "FreeResMod", hmod
end    
else
    rcy = VRMethod( "PRT_1", "PrintLine", 'Helvetica Bold', 14, 'ERROR - Failed to create the table...');


return

/*:VRX         WriteTable3
*/
WriteTable3: 
    /***** Define the table ********************************/

    table.0 = 17
    table.1 = 0 /* fill style */
    table.2 = 28 /* thickness */
    table.3 = 1
    table.4 = 8 /* header fill */
    table.5 = 28 /* header line thick */
    table.6 = 1
    table.7 = 12
    table.8 = 'Helvetica Bold'
    table.9 = 10
    table.10 = 26
    table.11 = 24
    table.12 = "<default>"
    table.13 = "<default>"
    table.14 = "<default>"
    table.15 = "<default>"
    table.16 = "<default>"
    table.17 = "<default>"

    /***** Make 3 columns ***********************************/

    Cols.0.0 = 3

    Cols.1.1 = 45
    Cols.1.2 = 'Column 1'

    Cols.2.1 = 50
    Cols.2.2 = '$cColumn 2'

    Cols.3.1 = 40
    Cols.3.2 = '$rColumn 3'

    rcy = VRMethod( "PRT_1", "DefineTable", "table.", "Cols.");

    if rcy then do

        /***** Change column headers for following pages ****************/
        
        call VRMethod "PRT_1", "ResetColHeader", 1, "New header 1"
        call VRMethod "PRT_1", "ResetColHeader", 2, "$rNew header 2"
        call VRMethod "PRT_1", "ResetColHeader", 3, "$cNew header 3"

        /***** Start printing a row *************************************/
        
        rcy = VRMethod( "PRT_1", "StartRow");

        /***** write to col 1 *******************************************/
        

        rcy = VRMethod( "PRT_1", "StartCol", 1);
        rcy = VRMethod( "PRT_1", "PrintRight", 'Helvetica', 10, 'This is some text in the first column. It is not very long,');
        
        /***** write to col 2 *******************************************/
        
        rcy = VRMethod( "PRT_1", "StartCol", 2);
        rcy = VRMethod( "PRT_1", "PrintJustified", 'Helvetica Bold', 10, 'This is some text in the second column. It is not very long,');
        rcy = VRMethod( "PRT_1", "PrintJustified",,,'This text has several lines and with a bit of luck should force a new page.');
        rcy = VRMethod( "PRT_1", "PrintJustified",,,'If it does then we have a test of a cell rolling over from one page to the next and we will not have to write any more.');
        
        /***** write to col 3 *******************************************/
        
        rcy = VRMethod( "PRT_1", "StartCol", 3);
        rcy = VRMethod( "PRT_1", "PrintCentered", 'Helvetica Bold', 14, 'This is some text in the third column. It is not very long,');
        
        /***** print out the row ****************************************/
        
        rcy = VRMethod( "PRT_1", "EndRow");
        rcy = VRMethod( "PRT_1", "NewPage");
        
        /***** start the next row ***************************************/
        
        rcy = VRMethod( "PRT_1", "StartRow");
        
        /***** write to col 1 *******************************************/
        
        rcy = VRMethod( "PRT_1", "StartCol", 1);
        rcy = VRMethod( "PRT_1", "PrintRight", 'Times New Roman', 10, 'This is some text in the first column. It is not very long,');
        
        /***** write to col 2 *******************************************/
        
        rcy = VRMethod( "PRT_1", "StartCol", 2);
        rcy = VRMethod( "PRT_1", "PrintLeft", 'Helvetica Bold', 10, 'This is some text in the second column. It is not very long and should be left justified.');
        rcy = VRMethod( "PRT_1", "PrintCentered",,,'This text has several lines and with a bit of luck should be centred.');
        rcy = VRMethod( "PRT_1", "PrintJustified",,,'This text here was designed to be justified and should roll over several lines, of course the last line will be left aligned.');
        rcy = VRMethod( "PRT_1", "PrintRight",,,'This last bit of text should finally show all the styles in one cell as it is right aligned.');
        
        /***** write to col 3 *******************************************/
        
        rcy = VRMethod( "PRT_1", "StartCol", 3);
        rcy = VRMethod( "PRT_1", "PrintJustified", 'Times New Roman', 8, 'This is some text in the third column. It is not very long,');
        
        /***** print out the row ****************************************/
        
        rcy = VRMethod( "PRT_1", "EndRow");
        
        /***** Terminate the table **************************************/
        
        rcy = VRMethod( "PRT_1", "EndTable");

    end
    else
        rcy = VRMethod( "PRT_1", "PrintLeft", 'Helvetica Bold', 14, 'ERROR - Failed to create the table...');


return

