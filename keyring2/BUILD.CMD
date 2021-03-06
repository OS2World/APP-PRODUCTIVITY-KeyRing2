rem make distribution WPIs
del build\common\*.* /n > build.log
del build\register\*.* /n  >> build.log
del build\sounds\*.* /n >> build.log
copy VREXTRAS.DLL build\common >> build.log
copy VRPRINT.DLL build\common >> build.log
copy VLMSG.DLL build\common >> build.log
copy KRICON.DLL build\common >> build.log
copy *.MSG    build\common >> build.log
copy KEYRING2.EXE build\common >> build.log
copy kr2.INF      build\common >> build.log
copy KRINI.DLL    build\common >> build.log
copy .\instboil\*.* build\common >> build.log
copy .\bmtapps\*.* build\common >> build.log
copy INTRO.MID build\sounds >> build.log
copy STARTUP.WAV build\sounds >> build.log
copy twilitzn.wav build\sounds >> build.log
copy wakeup.WAV build\sounds >> build.log

copy krypton.dll build\common >> build.log

rem Now make the WPI for Kevin
del kr2k.wpi >> build.log
kr2reg -p -e[kr2@idk-inc.com] -f[Kevin] -l[McCoy] >> build.log
copy .\dllbuild\kregistr.dll build\register >> build.log
copy .\dllbuild\readme.reg build\register >> build.log
wic kr2k.wpi -a 1 -cbuild\common * 2 -cbuild\register * 3 -cbuild\sounds * -s kr2k.wis >> build.log
wic kr2k.wpi -l >> build.log

rem Now make the Beta for email distribution
del kr2b.wpi >> build.log
kr2reg -b -e[kr2@idk-inc.com] -f[Beta] -l[Beta] >> build.log
copy .\dllbuild\kregistr.dll build\register >> build.log
copy .\dllbuild\readme.reg build\register >> build.log
wic kr2b.wpi -a 1 -cbuild\common * 2 -cbuild\register * 3 -cbuild\sounds * -s kr2b.wis >> build.log
wic kr2b.wpi -l >> build.log

rem use dummy crypter
copy kryptonc.dll build\common\krypton.dll >> build.log

rem Now make the WPI for WWW distribution
del kr2w.wpi >> build.log
kr2reg -d -e[kr2@idk-inc.com] -f[Demo] -l[Demo] >> build.log
copy .\dllbuild\kregistr.dll build\register >> build.log
copy .\dllbuild\readme.reg build\register >> build.log
wic kr2w.wpi -a 1 -cbuild\common * 2 -cbuild\register * 3 -cbuild\sounds * -s kr2w.wis >> build.log
wic kr2w.wpi -l >> build.log

