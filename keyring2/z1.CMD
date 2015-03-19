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

/* DeskMan/2: this entry for keyring2, generated on 2000/05/20 at 15:51:42 */
rc = SysCreateObject(,
                     "WPShadow",,
                     "keyring2",,
                     "<KeyRing2_Main_Product>",,
                     "NOPRINT=YES;" ||,
                     "PELICONPOS=175 344(1280 1024);" ||,
                     "SHADOWID=G:\keyring2;" ,,
                     reply);
If rc <> 1 Then Say "Object: keyring2 could not be created/updated !"; 
