unit os_test;
{
Returns a string description of the operating system, allowing the
calling program to take appropriate action (if it wants to).  Tests are
performed for the following:

    * Linux "dosemu" box  (thanks to Lin Ke-Fong)
    * Desqview / Taskview / Topview (variant of Joel Bergen's method)
    * 4DOS and NDOS
    * DR-DOS        (My first attempt at Assembler; not the fastest)
    * Novell DOS    (code but it does the job, and runs on 8088's too)
    * OS/2
    * Windows, including Win95 and WinNT
    * ...and ordinary DOS via the TP6 DosVersion function! :)
}

interface
function operating_system : string;

{sample call :  writeln(operating_system);  See the demo program on
the end of this message }

{----------------------------------------------------------------------}
implementation

uses dos;

var regs : registers;
    what_OS: word;  s, temp : string;

{======================================================================}

   function findWin3 : word;  assembler;
   {lets a DOS program test for Windows 3.x.
   Returns a value as follows:
      0 = no Windows
      1 = Real/Standard mode
      other value = Enhanced Mode.
            lo(findwin3) = major version
            hi(findwin3) = minor version }

   Asm
      mov    ax,1600h
      int    2Fh
      cmp    al,1
      jbe    @realstd
      cmp    al,80h
      jae    @realstd
      mov    ax,1600h  {if it's Windows, then get version}
      int    2Fh
      jmp    @end
      @realstd:
      mov    ax,4680h
      int    2Fh
      or     ax,ax
      jnz    @noWin
      mov    al,1
      jmp    @end
      @noWin:
      xor    ax,ax
      @end:
   end; {find Win3}

{--------------------------------------------------------------------}

   function in_v86 : boolean; assembler;
   {checks for an 8086 "virtual machine" session - will return true if
   in Windows, OS/2, or a multitasking DOS system.  Uses the
   give-a-time-slice interrupt}

   asm
      mov  ax,$1680
      int  $2F
      not  al          {al = 0 if virtual machine}
      mov  cl,7
      shr  al,cl       {make this a boolean}
   end;

{-------------------------------------------------------------------}
{   Lin Ke-Fong's method to detect Linux "dosemu" DOS box           }
{       All I've done is correct 2 minor typing errors              }
{-------------------------------------------------------------------}

  function dosemu_Detect:boolean; assembler;
{ This function use two methods (which are "official") to detect dosemu.

  First if dosemu is present, the BIOS date string at 0xF000:0xFFF5
  should be "02/25/93". Second interrupt $E6 called with ah = 0 should
  return $AA55 in ax register when in a dosemu dos box. Note that
  interrupt $E6 should be "initialized" to point to an IRET instruction
  since it is often pointed on nothing by BIOS. }

  asm
   push ds   {save important registers}
   push es
   push di
   push si
{ check for the BIOS date }
   mov  ax,$F000
   mov  ds,ax
   mov  bx,$FFF5
   mov  ax,'20'
   cmp  word ptr [bx],'20'
   jne  @no_dosemu
   cmp  word ptr [bx+2],'2/'
   jne  @no_dosemu
   cmp  word ptr [bx+4],'/5'
   jne  @no_dosemu
   cmp  word ptr [bx+6],'39'
   jne  @no_dosemu
{ initialize interrupt $E6 to an IRET }
   xor  ax,ax
   mov  ds,ax
   mov  bx,$E6 * 4
   les  di,[bx]
   mov  bl,es:[di]
   mov  byte ptr es:[di],$CF { put an iret instruction }
{ call the installation check interrupt (int $E6 with ah = 0) }
   xor  ah,ah
   int  $E6
   mov  es:[di],bl           { restore the old instruction }
   cmp  ax,$AA55
   jne  @no_dosemu
   mov  ax,01h
   jmp  @end
@no_dosemu:
   xor  ax,ax
@end:
   pop si
   pop di
   pop es
   pop ds
end;  {dosemu detect}

{-----------------------------------------------------------------}
{Desqview, Topview, Taskview detection.  Also gets desqview version}
{------------------------------------------------------------------}

   function desqview_detect : byte; assembler;
     asm
       push ds   {save important registers}
       push es
       push di
       push si
       mov  ax,$1022
       mov  dx,0
       int $15       {generic test for desqview, topview,taskview}
       cmp  bx,$0a01 {is it Desqview ?}
       jne  @no_desq    {no...}
     {check desqview version}
       mov  ax,$2b01
       mov  cx,$4445
       mov  dx,$5351
       int  $21
       cmp  al,$FF    {double-check that it _is_ Desqview}
       jne  @no_desq  {no...}
       jmp  @end
       @no_desq:
       cmp  bx,01h      {is it Taskview ?}
       jne @no_task    {no...}
       mov  bx,$FE     {our flag for Taskview}
       @no_task:
       cmp  bx,00h      {is it Topview ?}
       jne @no_view    {problem - not desqview, taskview or topview !}
       mov bx,$FD      {our flag for Topview}
       jmp  @end
       @no_view:
       mov  bx,$0000 {our flag for "not installed"}
       @end:
       mov  ax,bx
       {version number (FEh = Taskview, FDh = Topview, 0 = not
        installed, anything else = Desqview version}
       pop si            {tidy up...}
       pop di
       pop es
       pop ds
     end; {desqview_detect}

{---------------------------------------------------------------}

   function fourDOS_detect : byte; assembler;
   {detects 4DOS and NDOS, and version}

   asm
      push ds              {save important registers}
      push es
      push di
      push si
      mov  ax,$d44d
      mov  bx,0
      int  $2F         {generic test for 4DOS & NDOS}
      cmp  ax,$44DD    {is it 4DOS ?}
      je   @end
      cmp  ax,$44ee    {is it NDOS ?}
      je   @end
      mov ax,0       {our flags for "not installed"}
      mov bx,0       {ax = $DD for 4DOS, $EE for NDOS, 0 for not
                      installed. lo(bx) = major version, hi(bx) =
                      minor version }
      @end:
      pop si               {tidy up...}
      pop di
      pop es
      pop ds
   end; {fourdos_detect}

{-------------------------------------------------------------------}

   function DRNovellDOS : byte; assembler;
   {
   Correctly identify DR-DOS and Novell DOS.  The TP6 DosVersion
   function returns "3.31" for any DR-DOS version and "6.00" for
   Novell DOS 7.

   hi(DRNovellDOS)= 10h for original Novell DOS 7
                         or single-user DR-DOSes
                  = 14h for multiuser DR-DOSes
                  = 0 for Novell DOS 7 update 15 (AND IT'S MUCH BETTER
                                                  THAN MS-DOS 6.22 ;)
   lo(DRNovellDOS)= 60h,63h,64h for pre-5.00 DR-DOS
                  = 65h for DR-DOS 5.00
                  = 67h for DR-DOS 6.00
                  = 70h for DR PalmDOS
                        (ROM version of DR-DOS 6 for handheld PDA's)
                  = 71h for DR-DOS 6.00 update
                  = 72h for Novell DOS 7
   DRNovellDOS set to 0000h if all tests fail; ie: not DR/Novell DOS
   }

   asm
      push ds   {save important registers}
      push es
      push di
      push si
      mov ax,$4452  {check for DR/Novell DOS}
      stc           {carry flag MUST be set}
      int $21
      mov cx,ax     {put return code (if any) into cx for a moment...}
      mov ax,0
      lahf          {put flags in ah}
      mov bx,ax     {...then into bx}
      clc           {clear carry flag only}
      mov ax,0
      lahf
      cmp ax,bx     {this compares the earlier carry flag to current}
      jne @not_DR   {if earlier carry flag was set on return INT21}
                    {it's not DR/Novell DOS!}
      {now check for which species of DR/Novell DOS is in use}
      mov ax,cx     {restore the originally returned ax value}
      cmp ah,10h
      je @end      {it's Novell DOS 7 or a single-user DR-DOS}
      cmp ah,0
      je @end      {it's Novell DOS 7 update}
      cmp ah,14h
      je @end      {it's a multiuser DR-DOS...}
      @not_DR:     {return 0 in ah and al if not DR or Novell DOS}
      mov ah,0
      mov al,0
      @end:
      pop si    {tidy up...}
      pop di
      pop es
      pop ds
   end; {DRNovellDOS}

{---------------------------------------------------------------------}
   function DRNovell_multitask : boolean; assembler;
   {checks if the DR-DOS 6 TASKMAX taskswitcher, or Novell DOS 7
   TASKMGR multitasker is loaded.  Check that the operating system
   is DR or Novell before calling, or result is meaningless}

   asm
      mov   ax,$2700
      int   $2F
      cmp   al,$FF
      jne   @nomulti
      mov   cl,7
      shr   al,cl     {make it true}
      jmp   @end
      @nomulti:
      mov   cl,8
      shr   al,cl     {make it false}
      @end:
   end; {DRNovell_multitask}

{========   main  function  =========================================}
function operating_system : string;
begin
what_OS:= 0;

{check for Linux first}
if dosemu_detect then
   begin
   operating_system:= 'Linux DOS emulator';
   exit;    {I'm being cautious; I have no idea what the rest
             of this operating_system function might do when
             run in Linux!}
   end;

{check for Desqview, Taskview, Topview}
what_OS:= desqview_detect;  
if what_OS <> 0 then
   case what_OS of
        $FE : temp:= 'Taskview';
        $FD : temp:= 'Topview';
        else begin
             str(what_OS:2,s);
             temp:= 'Desqview'+s;  {include version}
             end;
        end; {case}

{Desqview,etc not found; so check for 4DOS/NDOS}
if what_OS = 0 then  
   begin
   what_OS:= lo(fourDOS_detect);
   case what_OS of
      $DD : begin
            str(lo(regs.bx):1,s);
            temp:= '4DOS '+s;
            str(hi(regs.bx):2,s);
            temp:= temp+'.'+s;
            end;
      $EE : begin
            str(lo(regs.bx):1,s);
            temp:= 'NDOS '+s;
            str(hi(regs.bx):2,s);
            temp:= temp+'.'+s;
            end;
      end; {case}
   end; {4DOS/NDOS detection}

{Desqview, etc & 4DOS/NDOS not found; check for DR & Novell DOSes}
if what_OS = 0 then
   begin
   what_OS:= DRNovellDOS;
   if lo(what_OS) <> 0 then
      begin
      temp:='';
      if hi(what_OS) = $14 then temp:='multiuser ';
      case lo(what_OS) of
           $60,$63,$64 : temp:= temp+'DR-DOS <5.00';
           $65         : temp:= temp+'DR-DOS 5.00';
           $67,$71     : temp:= temp+'DR-DOS 6.00';
           $70         : temp:= temp+'DR PalmDOS';
           $72         : temp:= temp+'Novell DOS 7';
           else temp:= 'vintage DR-DOS'; {prob. DR Concurrent DOS}
           end; {case}
      if DRNovell_multitask then  {check DR/Novell task managers}
         begin
         if lo(what_OS) = $72 then
           temp:= temp+' (TASKMGR active)'
            else temp:= temp+' (TASKMAX active)';
         end
        else begin
             if lo(what_OS) = $72 then
               temp:= temp+' (TASKMGR not active)'
                else temp:= temp+' (TASKMAX not active)';
             end;
      end; {if what_OS <> 0}
   end; {check for DR/Novell DOS}

{Desqview, 4DOS, DR/Novell DOS not found; check for MS-DOS and OS/2}
if what_OS = 0 then  {check for DOS & OS/2}
   begin
   temp:='';
   what_OS:= DOSversion;
   if lo(what_OS) >= 10 then  {is it OS/2 ?}
            begin
            str( (lo(what_OS) div 10),s);
            temp:= 'OS/2 '+s;
            end
           else
            begin
            str(lo(what_OS),s);
            temp:= 'DOS '+s;
            end;
   str(hi(what_OS),s);
   temp:= temp+'.'+s;
   end; {check for DOS & OS/2}


{if what_OS is STILL zero, this must be a really unusual system!}
if what_OS = 0 then
     begin operating_system:= 'no idea'; exit; end;


{Check for Windows; if it's Win 3.x then add the details to our
answer in the form "DOS x.xx (in Windows xxx... )"}

what_OS:= findwin3;
case what_OS of
     0 : temp:= temp;               {Windows is not running.  I know
                                    this assignment looks silly, but
                                    it avoids problems later on}
     1 : temp:= temp+' (in Windows Real/Standard Mode)';
     else
         begin                      {check for newer Win versions}
         if lo(dosversion) = 7 then
            temp:= 'Windows 95'     {wipe out any info so far}
         else
         if ((lo(dosversion) = 5) and (getenv('OS') = 'Windows_NT'))
          then temp:= 'Windows NT'     {wipe out any info so far}
            else begin                 {it's Windows 3.x Enhanced}
              str(lo(what_OS),s);
              temp:= temp+' (in Windows '+s;
              str(hi(what_OS),s);
              temp:= temp+'.'+s+' Enhanced Mode)';
              end;
         end;
     end; {case}

{
Check for a "virtual 8086 machine" - this returns True for any
multitasker, so check for Win, OS/2, Desqview, and DR/Novell
taskmanagers first before testing for multitasking DOSes.  The
"temp" string (by now) contains the info we need.
}

if ((pos('Windows',temp) = 0) then
   if (pos('OS/2',temp) = 0)) then
      if (pos('TASKM',temp) = 0) then
         if (pos('view',temp) = 0) then
            if in_v86 then temp:= temp+' (DOS multitasker)';

operating_system:= temp;

end; {operating_system}
{---------------------------------------------------------------}
begin
end.  {os_test unit}


{======  DEMONSTRATION PROGRAM  ==============================}
{ cut this out and save as os_demo.pas before compiling       }

program os_demo;

uses dos,os_test;

begin
writeln; writeln; writeln('The actual operating system is :');
writeln(operating_system);
writeln;
writeln('The Turbo Pascal DosVersion function reports DOS version ',
             lo(dosversion),'.',hi(dosversion));
writeln('Press ENTER to continue...');
readln;
end.

