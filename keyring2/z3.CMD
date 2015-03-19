/* REXX - DeskMan/2 generated this file              */
/* version: 2 rel. 0                                  */
/* (C) Copyright 1993-1996                            */
/*            Development Technologies, Inc.          */
/*            All Rights Reserved                     */
/* A DeskMan/2 license is required for each computer  */
/* system on which this program is being executed.    */
 
Call RxFuncAdd 'SysLoadFuncs','REXXUTIL','SysLoadFuncs';
Call SysLoadFuncs; 

Say 'Please enter the option for restoring objects!';
Say 'Enter R - for Replace, U - for Update, S - for Skip';
Say '      if an object already exists.';
reply = Translate(SysGetKey()); 
If reply <> 'S' & reply <> 'U' & reply <> 'R' Then reply = 'S';  
If reply = 'S' Then reply = 'F';  
Say ''; 

/* DeskMan/2: this entry for keyring2, generated on 2000/05/20 at 15:52:52 */
rc = SysCreateObject(,
                     "WPFolder",,
                     "keyring2",,
                     "<Drive_G>",,
                     "DMExtFOLDER=YES;" ||,
                     "DEFAULTVIEW=CONTENTS;" ||,
                     "NOPRINT=YES;" ||,
                     "ICONNRESOURCE=1," ||,
                     "6," ||,
                     "PMWP.DLL;" ||,
                     "DMExtFolderSelfClose=NONE;" ||,
                     "DMExtIconTextColorICON=FFFFFFDD;" ||,
                     "ICONTEXTCOLOR=FFFFFFDD;" ||,
                     "TREETEXTCOLOR=FFFFFFEF;" ||,
                     "DMExtIconTextColorTREE=FFFFFFEF;" ||,
                     "DETAILSTEXTCOLOR=FFFFFFDD;" ||,
                     "DMExtIconTextColorDETAILS=FFFFFFDD;" ||,
                     "DMExtUseArchive=PARENT;" ||,
                     "DeskManFOLDER=YES;" ||,
                     "ICONVIEW=NONGRID," ||,
                     "NORMAL;" ||,
                     "TREEVIEW=LINES," ||,
                     "MINI;" ||,
                     "DETAILSVIEW=MINI;" ||,
                     "MENUS=LONG;" ||,
                     "ICONFONT=9.WarpSans;" ||,
                     "DETAILSFONT=9.WarpSans;" ||,
                     "TREEFONT=9.WarpSans;" ||,
                     "ALWAYSSORT=YES;" ||,
                     "DETAILSCLASS=WPFileSystem;" ||,
                     "DEFAULTSORT=NAME;" ||,
                     "BACKGROUND=C:\OS2\BITMAP\PLASTER.BMP," ||,
                     "T," ||,
                     "1," ||,
                     "I," ||,
                     "DEFAULT;" ||,
                     "ICONGRIDSIZE=0," ||,
                     "0;" ||,
                     "MENUBAR=YES;" ,,
                     reply);
If rc <> 1 Then Say "Object: keyring2 could not be created/updated !"; 
