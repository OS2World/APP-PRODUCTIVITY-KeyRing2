del kr2f.wpi
wic kr2f.wpi -a 1 VLMSG.DLL    
wic kr2f.wpi -a 1 KRICON.DLL    
copy kryptonb.dll .\dllbuild\krypton.dll
wic kr2f.wpi -a 1 -c.\dllbuild krypton.dll  
wic kr2f.wpi -a 1 DUTCH.MSG    
wic kr2f.wpi -a 1 ENGLISH.MSG  
wic kr2f.wpi -a 1 HSILGNE.MSG  
wic kr2f.wpi -a 1 KEYRING2.EXE 
wic kr2f.wpi -a 1 kr2.INF      
wic kr2f.wpi -a 1 KRINI.DLL    
wic kr2f.wpi -a 1 LANGUAGE.MSG 
wic kr2f.wpi -a 1 POLSKI.MSG   
wic kr2f.wpi -a 1 spanish.msg  
wic kr2f.wpi -a 1 -c.\instboil FILE_ID.DIZ  
wic kr2f.wpi -a 1 -c.\instboil IDK.ICO      
wic kr2f.wpi -a 1 -c.\instboil IDKO.ICO     
wic kr2f.wpi -a 1 -c.\instboil INFO.ICO     
wic kr2f.wpi -a 1 -c.\instboil INFO1.ICO    
wic kr2f.wpi -a 1 -c.\instboil INFO1_O.ICO  
wic kr2f.wpi -a 1 -c.\instboil kr2.ICO      
wic kr2f.wpi -a 1 -c.\instboil LANGUAGE.TXT 
wic kr2f.wpi -a 1 -c.\instboil PLASTER.BMP  
wic kr2f.wpi -a 1 -c.\instboil readme.now   
wic kr2f.wpi -a 1 -c.\instboil readme.txt   
wic kr2f.wpi -a 1 -c.\instboil REGISTER.TXT 
wic kr2f.wpi -a 1 -c.\instboil VREXTRAS.DLL 
wic kr2f.wpi -a 1 -c.\bmtapps ORDER.FRM    
wic kr2f.wpi -a 1 -c.\bmtapps PURCHASE.APP 
wic kr2f.wpi -a 1 -c.\bmtapps PURCHASE.DOC 
wic kr2f.wpi -a 1 -c.\bmtapps PURCHASE.EXE 
wic kr2f.wpi -a 1 -c.\bmtapps REGISTER.FRM 
kr2reg -p -e[kr2@idk-inc.com] -f[Kevin] -l[McCoy]
copy .\dllbuild\kregistr.dll .\
copy .\dllbuild\readme.reg .\
wic kr2f.wpi -a 2 -c.\dllbuild readme.reg
wic kr2f.wpi -a 2 -c.\dllbuild KREGISTR.DLL        
wic kr2f.wpi -a 3 INTRO.MID                                     
wic kr2f.wpi -a 3 STARTUP.WAV                                  
wic kr2f.wpi -a 3 twilitzn.wav                                
wic kr2f.wpi -a 3 wakeup.WAV                                  
wic kr2f.wpi -s kr2.wis
del kr2w.wpi
wic kr2w.wpi -a 1 VLMSG.DLL    
wic kr2w.wpi -a 1 KRICON.DLL    
copy kryptonc.dll .\dllbuild\krypton.dll
wic kr2w.wpi -a 1 -c.\dllbuild krypton.dll  
wic kr2w.wpi -a 1 DUTCH.MSG    
wic kr2w.wpi -a 1 ENGLISH.MSG  
wic kr2w.wpi -a 1 HSILGNE.MSG  
wic kr2w.wpi -a 1 KEYRING2.EXE 
wic kr2w.wpi -a 1 kr2.INF      
wic kr2w.wpi -a 1 KRINI.DLL    
wic kr2w.wpi -a 1 LANGUAGE.MSG 
wic kr2w.wpi -a 1 POLSKI.MSG   
wic kr2w.wpi -a 1 spanish.msg  
wic kr2w.wpi -a 1 -c.\instboil FILE_ID.DIZ  
wic kr2w.wpi -a 1 -c.\instboil IDK.ICO      
wic kr2w.wpi -a 1 -c.\instboil IDKO.ICO     
wic kr2w.wpi -a 1 -c.\instboil INFO.ICO     
wic kr2w.wpi -a 1 -c.\instboil INFO1.ICO    
wic kr2w.wpi -a 1 -c.\instboil INFO1_O.ICO  
wic kr2w.wpi -a 1 -c.\instboil kr2.ICO      
wic kr2w.wpi -a 1 -c.\instboil LANGUAGE.TXT 
wic kr2w.wpi -a 1 -c.\instboil PLASTER.BMP  
wic kr2w.wpi -a 1 -c.\instboil readme.now   
wic kr2w.wpi -a 1 -c.\instboil readme.txt   
wic kr2w.wpi -a 1 -c.\instboil REGISTER.TXT 
wic kr2w.wpi -a 1 -c.\instboil VREXTRAS.DLL 
wic kr2w.wpi -a 1 -c.\bmtapps ORDER.FRM    
wic kr2w.wpi -a 1 -c.\bmtapps PURCHASE.APP 
wic kr2w.wpi -a 1 -c.\bmtapps PURCHASE.DOC 
wic kr2w.wpi -a 1 -c.\bmtapps PURCHASE.EXE 
wic kr2w.wpi -a 1 -c.\bmtapps REGISTER.FRM 
kr2reg -d
wic kr2w.wpi -a 2 -c.\dllbuild readme.reg
wic kr2w.wpi -a 2 -c.\dllbuild KREGISTR.DLL              
wic kr2w.wpi -a 3 INTRO.MID                                     
wic kr2w.wpi -a 3 STARTUP.WAV                                  
wic kr2w.wpi -a 3 twilitzn.wav                                
wic kr2w.wpi -a 3 wakeup.WAV                                  
wic kr2w.wpi -s kr2.wis

