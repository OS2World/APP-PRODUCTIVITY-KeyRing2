/*******************************************************************/
/* Written by Krzysztof Bytnerowicz                                */
/*******************************************************************/
/* add new language file (2) to merged language file (1)           */
/* and create new merged language file                             */
/*                                                                 */
/*******************************************************************/
/* 27.02.2000 KB - Development started                             */
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
INPUTF2 = "SPANISH.MSG"
TRGFILE = "MERGED.MSG"
/* number of languages in file1 */
NUMLNES1 = 0
NUMLNES2 = 0
NUMLOUT  = 0

/* trace all */
  signal on syntax name Syntax
  signal on halt name Halt


 /* major loop starts here */
 do while lines(INPUTF1) > 0
   STRE = linein(INPUTF1)  /* read English */
   NUME = substr(STRE,1,6)
   STRP = linein(INPUTF1)  /* read Polish */
   NUMP = substr(STRP,1,6)
   if NUME \= NUMP then do
     say 'inconsistent records in ' INPUTF1 NUME
     leave
   end
   call lineout TRGFILE,STRE  /* write English */
   call lineout TRGFILE,STRP  /* write Polish */
   NUMLNES1 = NUMLNES1 + 2
   NUMLOUT  = NUMLOUT + 2
   if lines(INPUTF2) > 0 then do
     STRS = linein(INPUTF2)   /* read Spanish */
     NUMS = substr(STRS,1,6)
     if NUME \= NUMS then do
       say 'inconsistent records in ' INPUTF2 NUME
       leave
     end
     NUMLNES2 = NUMLNES2 + 1
     call lineout TRGFILE,STRS  /* write Spanish */
     NUMLOUT  = NUMLOUT + 1
   end
   else do
     say 'premature end of' INPUTF2
     leave
   end
 end

call lineout TRGFILE    /* close output */
/* summarise the results */
say "lines1=" right(NUMLNES1,8,'0')
say "lines2=" right(NUMLNES2,8,'0')
say "lineso=" right(NUMLOUT,8,'0')
Exit

Syntax:
  say 'Error' rc 'in line' sigl':' errortext(rc)
  say sigl':' sourceline(sigl)
  call lineout TRGFILE
  exit
return

Halt:
   say date('S') time('N') 'langmerg.CMD interrupted by Ctrl-C, ShutDown, or closing of WorkArea.'
   call lineout TRGFILE
   exit
return
