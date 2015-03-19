/*******************************************************************/
/* Written by Krzysztof Bytnerowicz                                */
/*******************************************************************/
/* split merged language file into individual languages            */
/*                                                                 */
/*******************************************************************/
/* 27.02.2000 KB - Development started                             */
/* 01.03.2000 KB - character count for each language               */
/*                                                                 */
/*                                                                 */
/*                                                                 */
/*                                                                 */
/*******************************************************************/
/* Wish List:                                                      */
/*                                                                 */
/*******************************************************************/
/* may contain more than one language already */
INPUTF1 = "LANGUAGE.MSG"
/* number of languages in file1 */
NUMLNES1 = 0
OUTFILE.0 = 0
NUMLOUT.0 = 0
LANG.0 = 0
CHAR.0 = 0

/* trace all */
  signal on syntax name Norexx
  signal on halt name Halt

/* define rexxutil functions */
  call RxFuncAdd 'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs'
  call SysLoadFuncs
  signal on syntax name Syntax

 /* read and decode file header */
 j = 0
 do while lines(INPUTF1) > 0
   j = j + 1
   STR = linein(INPUTF1)
   NUMLNES1 = NUMLNES1 + 1
   parse upper VAR STR WRD1 WRD2 WRD3 .
   if WRD2 = "LANGUAGES" then leave
   HDR.j = STR
 end
 HDR.0 = j
 if lines(INPUTF1) = 0 then do
   say 'wrong file format'
   Exit
 end

 /* read the languages list */
 i = 0
 do while lines(INPUTF1) > 0
   STR = linein(INPUTF1)
   NUMLNES1 = NUMLNES1 + 1
   parse upper VAR STR WRD1 WRD2 WRD3 WRD4 .
   if WRD2 = "END" then leave
   i =  i + 1
   LANG.i = WRD4
 end
 if lines(INPUTF1) = 0 then do
   say 'wrong file format'
   Exit
 end
 LANG.0 = i
 OUTFILE.0 = i

/* create language filenames and delete targets */
 i = 0
 do  while i < OUTFILE.0
   i = i + 1
   OUTFILE.i = LANG.i || '.MSG'
   rc = SysFileDelete(OUTFILE.i)
   NUMLOUT.i = 0
   CHAR.i = 0
 end
 CHAR.0 = i
 NUMLOUT.0 = i

/* prime language files with the headers */
 i = 0
 do  while i < OUTFILE.0
   i = i + 1
   do j = 1 to HDR.0 - 1
     call lineout OUTFILE.i,HDR.j
     NUMLOUT.i = NUMLOUT.i + 1
   end
 end

/* skip one line */
   STR = linein(INPUTF1)
   NUMLNES1 = NUMLNES1 + 1

/* main loop here */
 do while lines(INPUTF1) > 0
   i = 0
   do  while i < OUTFILE.0
     i =  i + 1
     STR = linein(INPUTF1)
     NUMLNES1 = NUMLNES1 + 1
     if STR = ":END OF FILE"  then leave
     NUML.i = substr(STR,1,6)
     CHAR.i = length(STR) + CHAR.i
     call lineout OUTFILE.i,STR
     NUMLOUT.i = NUMLOUT.i + 1
   end
   i = 0
   do  while i < OUTFILE.0 - 1
     i =  i + 1
     j =  i + 1
     if NUML.i \= NUML.j then do
     say 'line nembers inconsistent' NUML.i NUML.j
     end
   end
 end
 if STR \= ":END OF FILE"  then do
   say "premature end of" INPUTF1
   exit
  end

/* summarise the results */
 say "total input lines   " right(NUMLNES1,8,'0')
 i = 0
   do  while i < OUTFILE.0
   i =  i + 1
     STR = linein(INPUTF1)
     say "lines/chars" left(LANG.i,8,' ') right(NUMLOUT.i,8,'0') right(CHAR.i,8,'0')
   end
Exit

Syntax:
  say 'Error' rc 'in line' sigl':' errortext(rc)
  say sigl':' sourceline(sigl)
  exit
return

Halt:
   say date('S') time('N') 'langsplt.CMD interrupted by Ctrl-C, ShutDown, or closing of WorkArea.'
   exit
return
NoREXX:
   say 'Unable to load the REXXLIBs.  Either the *.DLL file'
   say 'is not on the LIBPATH or REXX support is not installed on this system.'
   exit
return
