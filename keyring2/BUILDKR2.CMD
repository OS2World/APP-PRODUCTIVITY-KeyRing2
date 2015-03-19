/* Rexx Keyring/2 builder script */

/* set up the paths */
krdir = "g:\keyring2"
instdir = "g:\keyring2\install"
boil = "g:\keyring2\instboil"
bmt = "g:\keyring2\bmtapps"

dom = "g:\keyring2\install\domestic\"
foreign = "g:\keyring2\install\foreign\"
pubdir = "g:\keyring2\install\public\"
instboil = "g:\keyring2\instboil\"
warpindir = "g:\p1\warpin\"
warpinrev = "warpin-0-9-4-2.zip"
warpin = warpindir || warpinrev
wipub = pubdir || "warpin"
vrobjloc = "C:\os2\dll\vrobj.dll"
wicexe = warpindir || "wic.exe "
des2blodir = "g:\des2blo"

paiddir = instdir || "paid" 
demodir = instdir || "demo"

omrel = dom || "rel"
forrel = foreign || "rel"
fordes = foreign || "des"
pubrel = pubdir || "keyring2"

/* compile the dummy registration */
"vpc -Vkregistr.vpo -B > kregistr.log"
"vpc -Vkrini.vpo -B > krini.log"
/*zzzz*/

/* compile the dummy encryption module */
"vpc -Vkryptonc.vpo -B > kryptonc.log"
"copy krypton.dll kryptonc.dll"

/* compile the DES encryption module */
"vpc -Vkryptond.vpo -B > kryptond.log"
"copy krypton.dll kryptond.dll"
/*zzzz*/


/* compile the blowfish encryption module */
"vpc -Vkryptonb.vpo -B > kryptonb.log"
"copy krypton.dll kryptonb.dll"

/* clean the target directories */
"del /n "|| dom || "*.*"
"del /n "|| foreign || "*.*"
"del /n "|| pubdir || "*.*"
"del /n "||  instdir || "\*.*"
"del /n "|| domrel || "\*.*"
"del /n "|| forrel || "\*.*"
"del /n "|| fordes || "\*.*"
/*zzzz*/


/* copy the FTP readme files */
"copy " || instboil || "readme.now " || domrel
"copy " || instboil || "readme.now " || forrel
"copy " || instboil || "readme.now " || fordes
"copy " || instboil || "readme.now " || pubrel
/*zzzz*/


/* copy the warpin installer zip to FTP directories */
"copy " || warpin || " " || domrel
"copy " || warpin || " " || forrel
"copy " || warpin || " " || fordes
"copy " || warpin || " " || wipub
/*zzzz*/


/* copy vrobj.dll files to FTP directories */
"copy " || vrobjloc || " " || domrel
"copy " || vrobjloc || " " || forrel
"copy " || vrobjloc || " " || fordes
"copy " || vrobjloc || " " || pubrel

/*zzzz*/

/* copy boilerplate files to install directory */
"copy *.msg " || instdir
"copy KEYRING2.EXE " || instdir
"copy kr2.INF " || instdir
"copy KRINI.DLL " || instdir
"copy VLMSG.DLL " || instdir
"copy VREXTRAS.DLL " || instdir
/*zzzz*/


/* do generic portion of release first (EXE, docs, and dummy encryption) */
call directory instdir;
wicexe || domrel || "\kr2.wpi -a 1 *.*"
/*zzzz*/


call directory bmt
wicexe || domrel || "\kr2.wpi -a 1 *.*"
/*zzzz*/


call directory boil
wicexe || domrel || "\kr2.wpi -a 1 *.*"
/*zzzz*/


/* create a domestic demo registration */
call directory krdir
"kr2reg -f[domdemo.rsp]"

/* copy dummy registration to instdir */
"copy " || krdir || "\KREGISTR.DLL " || instdir
"copy " || krdir || "\readme.reg " || instdir
/*zzzz*/


/* add dummy registration and regdoc to WPI package #2 */
call directory instdir
wicexe || domrel || "\kr2.wpi -a 2 kregistr.dll"
wicexe || domrel || "\kr2.wpi -a 2 readme.reg"
/*zzzz*/


/* add sound files to WPI package 3 */
call directory krdir;
wicexe || domrel || "\kr2.wpi -a 3 *.wav"
wicexe || domrel || "\kr2.wpi -a 3 *.mid"
/*zzzz*/


/* copy generic wpi to foreign and public directories */
call directory instdir;
"copy " || domrel || "\kr2.wpi " || forrel
"copy " || domrel || "\kr2.wpi " || fordes
"copy " || domrel || "\kr2.wpi " || pubrel

/*zzzz*/

/* add null encryption */
"copy " || krdir || "\kryptonc.dll " || instdir || "\krypton.dll"
wicexe || pubrel || "\kr2.wpi -a 1 krypton.dll"

/*zzzz*/

/* add new foreign blowfish encryption */
"copy " || krdir || "\kryptonb.dll " || instdir || "\krypton.dll" 
wicexe || forrel || "\kr2.wpi -a 1 krypton.dll"

/*zzzz*/

/* add old foreign DES encryption */
"copy " || krdir || "\kryptond.dll " || instdir || "\krypton.dll" 
wicexe || fordes || "\kr2.wpi -a 1 krypton.dll"

/*zzzz*/

/* add domestic encryption */
"copy " || krdir || "\kryptonb.dll " || instdir || "\krypton.dll" 
wicexe || domrel || "\kr2.wpi -a 1 krypton.dll"

/*zzzz*/

/* create des2blow package for DES foreign users */
"copy " || des2blodir || "\des2blo.exe " || instdir || "\des2blo.exe" 
"copy " || des2blodir || "\des2blo.ico " || instdir || "\des2blo.ico" 
"copy " || des2blodir || "\des2blo.wis " || instdir || "\des2blo.wis" 
/*zzzz*/

wicexe || fordes || "\des2blo.wpi -a 1 krypton.dll"
wicexe || fordes || "\des2blo.wpi -a 1 des2blo.exe"
wicexe || fordes || "\des2blo.wpi -a 1 des2blo.ico"
/*zzzz*/

wicexe || fordes || "\des2blo.wpi -s " || instdir || "\des2blo.wis"

/* finish */
call directory instdir;
wicexe || domrel || "\kr2.wpi -s " || krdir || "\kr2.wis"
/*zzzz*/

wicexe || forrel || "\kr2.wpi -s " || krdir || "\kr2.wis"
wicexe || fordes || "\kr2.wpi -s " || krdir || "\kr2.wis"
wicexe || pubrel || "\kr2.wpi -s " || krdir || "\kr2.wis"

/* cleanup */
/*zzzz*/

"del /n " || instdir || "\*.*"
/*zzzz*/


exit;
