/* Rexx Keyring/2 builder script */

/*
"vpc -Vkregistr.vpo -B > vp.log"
"vpc -Vkrini.vpo -B > vp.log"
"vpc -Vkryptonb.vpo -B >> vp.log"
"copy krypton.dll kryptonb.dll"
"vpc -Vkryptond.vpo -B >> vp.log"
"copy krypton.dll kryptond.dll"
*/

krdir = "g:\keyring2"
instdir = "g:\keyring2\install"
boil = "g:\keyring2\instboil"
bmt = "g:\keyring2\bmtapps"
domesticdir = "g:\keyring2\install\domestic\rel"

"del /n g:\keyring2\install\domestic\rel\*.*"
"del /n g:\keyring2\install\foreign\rel\*.*"

"del /n .\install\*.*"

"copy g:\keyring2\instboil\readme.txt g:\keyring2\install\domestic\rel"
"copy g:\keyring2\instboil\readme.txt g:\keyring2\install\foreign\rel"

"copy g:\p1\warpin\warpin-0-9-0.zip g:\keyring2\install\domestic\rel"
"copy g:\p1\warpin\warpin-0-9-0.zip g:\keyring2\install\foreign\rel"

"copy d:\os2\dll\vrobj.dll g:\keyring2\install\domestic\rel"
"copy d:\os2\dll\vrobj.dll g:\keyring2\install\foreign\rel"

"copy *.msg .\install"
"copy KEYRING2.EXE .\install"
"copy KRINI.DLL .\install"
"copy VLMSG.DLL .\install"
"copy VREXTRAS.DLL .\install"

/* do generic stuff first */

call directory instdir;

"g:\p1\warpin\wic g:\keyring2\install\domestic\rel\kr2.wpi -a 1 *.*"
call directory bmt
"g:\p1\warpin\wic g:\keyring2\install\domestic\rel\kr2.wpi -a 1 *.*"
call directory boil
"g:\p1\warpin\wic g:\keyring2\install\domestic\rel\kr2.wpi -a 1 *.*"

call directory instdir
pause
"copy g:\keyring2\kr2.INF"
"g:\p1\warpin\wic g:\keyring2\install\domestic\rel\kr2info.wpi -a 1 kr2.inf"
pause
"g:\p1\warpin\wic g:\keyring2\install\domestic\rel\kr2info.wpi -s g:\keyring2\kr2info.wis"
pause
"copy g:\keyring2\KREGISTR.DLL" 
"copy g:\keyring2\readme.reg"
"g:\p1\warpin\wic g:\keyring2\install\domestic\rel\kr2.wpi -a 2 kregistr.dll"
"g:\p1\warpin\wic g:\keyring2\install\domestic\rel\kr2.wpi -a 2 readme.reg"
call directory krdir;
"g:\p1\warpin\wic g:\keyring2\install\domestic\rel\kr2.wpi -a 3 *.wav"
"g:\p1\warpin\wic g:\keyring2\install\domestic\rel\kr2.wpi -a 3 *.mid"

call directory instdir;

/* copy generic wpi to foreign directory */
"copy .\domestic\rel\kr2.wpi g:\keyring2\install\foreign\rel\kr2.wpi"

/* add domestic encryption */
"copy g:\keyring2\kryptonb.dll krypton.dll"
"g:\p1\warpin\wic G:\KEYRING2\INSTALL\DOMESTIC\REL\kr2.wpi -a 1 krypton.dll"

/* add foreign encryption */
"copy g:\keyring2\kryptond.dll krypton.dll"
"g:\p1\warpin\wic g:\keyring2\install\foreign\rel\kr2.wpi -a 1 krypton.dll"

call directory instdir;

"g:\p1\warpin\wic g:\keyring2\install\domestic\rel\kr2.wpi -s g:\keyring2\kr2.wis"
"g:\p1\warpin\wic g:\keyring2\install\foreign\rel\kr2.wpi -s g:\keyring2\kr2.wis"

call directory domesticdir
"pkzip /add /max /sfx a:kr2inst"
exit;
