#
#                            FILER.MAK 5.51
#
#             Make file used to build B-Tree Filer 5.51
#
# This make file is designed to be used only with Borland's MAKE utility;
# it does NOT work with Microsoft's MAKE. To use this file, enter
#
#     MAKE -fFILER.MAK
#
# at the DOS command line. You MUST be in the directory where the make file
# is found, and the above command line assumes that MAKE.EXE is found on the
# DOS PATH.
#
# FILER.MAK is designed to work with Turbo Pascal 6.0-7.0, or Turbo Pascal
# for Windows 1.5, and either Turbo Assembler 1.0+ or the Microsoft
# Assembler 4.0+. This is made possible by MAKE's equivalent of
# conditional compilation directives. There are several macros that must
# either be defined or commented out, depending on what version of the
# compiler you have and what assembler, if any. See the comments in the
# various 'Defines' sections of this file for further instructions.

# You may also need to modify the definitions below in order for MAKE to be
# able to find your compiler and assembler. To comment out a macro or define
# insert '#' at the beginning of the line, as is being done here.

# This make file assumes the following environment:
#
#  - you have the Pascal libraries (*.TPL) in the same directory as your
#    compiler.
#  - your current directory is the directory this make file is found in (if
#    you accepted the default directory structure that the install program
#    suggested, this means the FILER directory).
#  - the following directory tree structure exists, which the install program
#    will build for you by default:
#
#      FILER
#      +---TOOLS
#      +---NETTOOLS
#      +---BROWSERS
#      +---DEMOS
#      +---UNITS
#
#    if you changed the defaults suggested by the install program, you *must*
#    alter the DirXxx macros below to define the new structure.

# All compiled units (except units that are just part of demo programs) will
# be placed in the FILER\UNITS directory. The compiled demo programs and
# their units are placed in the FILER\DEMOS directory.


# ------------------------------------------------------ Define target, etc

# Activate the required target platform: real mode, protected mode or
# Windows. Do not activate more than one.
ForRealMode=1
# ForPMode=1
# ForWindows=1

# Activate this line to use the Borland Pascal 7 compiler, deactivate
# if using a Turbo Pascal or Turbo Pascal for Windows compiler.
UseBP7=1

# Activate this line to use the Delphi DCC compiler, deactivate
# if using another compiler.
# UseDelphi=1

# Activate this line to Compile in debug information
# DEBUG=1


# ---------------------------------------------- Define DOS User Interfaces

# Activate only one of the following defines to compile the relevant demo
# programs. Note that you must manually alter the UseTPCRT and UseOPCRT
# defines in BTDEFINE.INC accordingly, otherwise a compile might fail.
TProOPro=No_TPro_OPro
# TProOPro=Both_TPro_OPro
# TProOPro=Only_TPro
# TProOPro=Only_OPro

# Activate this line to compile the Turbo Vision related units/demos.
# WantTV=1


# -------------------------------------------------- Define Assembler Stuff

# Set this to 1 for Turbo Assembler (TASM.EXE), or comment it out for
# Microsoft Assembler (MASM.EXE).
tasm=1

# Comment this line out if you do not have an assembler. If this macro is
# active, all ASM files will be assembled into OBJ files.
HaveAssembler=1


# ---------------------------------------------- Define Directory Structure

# This set of macros define the directory structure for B-Tree Filer's
# source code files and demo programs.
DirBase=\FILER                # this *must* be the default directory
DirTools=$(DirBase)\TOOLS
DirNetTools=$(DirBase)\NETTOOLS
DirBrowsers=$(DirBase)\BROWSERS
DirDemos=$(DirBase)\DEMOS
DirUnits=$(DirBase)\UNITS

# These macros define the directories where your command line compiler and
# assembler are found. If they can be found on the DOS PATH then leave these
# macros defined but empty (do not specify anything after the equals sign).
# If your assembler or compiler are not located in a directory on the DOS
# PATH, you must alter these macros to the directories where they are found.
# You must end the directory path with a backslash.
# For example, if your copy of BPC.EXE is located in the directory C:\BP7
# then you would change the definition of DirCompiler to
#    DirCompiler=C:\BP7\

DirCompiler=c:\bp\bin\                # do not remove this comment
DirAssembler=                         # do not remove this comment
!if $d(UseDelphi)
DirWinDOS=c:\delphi\source\rtl70
!endif

# Define this macro to show the directories where your OPro and/or TPro
# units are found. The format of the macros value follows the DOS PATH
# format, for example if you have the OPro units in C:\OPRO and the TPro
# units in C:\TPRO, specify the following:
#   DirOproTPro=C:\OPRO;C:\TPRO
#
DirOProTPro=


# ----------------------------------- Other factors that affect compilation
#
# Note that you must edit BTDEFINE.INC to specify a network option
# and other conditional defines that affect B-Tree Filer

###########################################################################
# From this point there are no more defines that need to be reviewed or   #
# changed.                                                                #
###########################################################################

# --------------------------------------------------------- Compiler macros
!if $d(tasm)
Assemble=$(DirAssembler)TASM.EXE
!else
Assemble=$(DirAssembler)MASM.EXE
!endif

uext=TPU
BP7Target=

!if $d(UseBP7)
compiler=BPC.EXE
!if $d(ForRealMode)
BP7Target=-CD
!elif $d(ForPMode)
BP7Target=-CP
uext=TPP
!else
BP7Target=-CW
uext=TPW
!endif
!elif $d(ForRealMode)
compiler=TPC.EXE
!elif $d(UseDelphi)
compiler=DCC.EXE
uext=DCU
!else
compiler=TPCW.EXE
!endif

!if $d(DEBUG)
DebugDirectives=-$D+ -$L+ -V
!else
DebugDirectives=-$D- -$L-
!endif

# Add any extra compiler directives after the /M on this line
!if $d(ForWindows)
!if $d(UseDelphi)
Compile=$(DirCompiler)$(compiler) $(BP7Target) $(DebugDirectives) /M /L /u$(DirWinDOS)
!else
Compile=$(DirCompiler)$(compiler) $(BP7Target) $(DebugDirectives) /M /L
!endif
!else
!if $(TProOPro)==No_TPro_OPro
Compile=$(DirCompiler)$(compiler) $(BP7Target) $(DebugDirectives) /M /L
!else
Compile=$(DirCompiler)$(compiler) $(BP7Target) $(DebugDirectives) /M /L -u$(DirOProTPro)
!endif
!endif


# ------------------------------------ Force evaluation of all dependencies

!if $d(ForRealMode)
!ifdef WantTV
dummy : units demos nonwindemos realdemos tvdemo
!else
dummy : units demos nonwindemos realdemos
!endif
!elif $d(ForPMode)
!ifdef WantTV
dummy : units demos nonwindemos pmodedemos tvdemo
!else
dummy : units demos nonwindemos pmodedemos
!endif
!else
dummy : units demos windemos
!endif

units : $(DirUnits)\BldNetTl.exe  \
        $(DirUnits)\BldFiler.exe  \
        $(DirUnits)\BldTools.exe  \
        $(DirUnits)\BldBrows.exe

demos : $(DirDemos)\NBChat.exe  \
        $(DirDemos)\NBSend.exe  \
        $(DirDemos)\NISend.exe  \
        $(DirDemos)\NSSend.exe  \
        $(DirDemos)\MesExamp.exe  \
        $(DirDemos)\SPX2Way.exe  \
        $(DirDemos)\NetInfo.exe  \
        $(DirDemos)\Traffic.exe \
        $(DirDemos)\TTSFiler.exe

!if $d(ForRealMode)
!if $(TProOPro)==Only_OPro
realdemos : oprodemos \
            $(DirDemos)\BigSort.exe
!elif $(TProOPro)==Only_TPro
realdemos : tprodemos \
            $(DirDemos)\BigSort.exe
!elif $(TProOPro)==Both_TPro_OPro
realdemos : oprodemos \
            tprodemos \
            $(DirDemos)\BigSort.exe
!else
realdemos : $(DirDemos)\BigSort.exe
!endif
!endif

!if $d(ForPMode)
!if $(TProOPro)==Only_OPro
pmodedemos : oprodemos
!elif $(TProOPro)==Only_TPro
pmodedemos : tprodemos
!elif $(TProOPro)==Both_TPro_OPro
pmodedemos : oprodemos \
,             tprodemos
!else
# a dummy make clause: filer.mak exists
pmodedemos : filer.mak
!endif
!endif

tvdemo : $(DirDemos)\TVIsDemo.exe

tprodemos : $(DirDemos)\NetDemo.exe

oprodemos : $(DirDemos)\OPIsDemo.exe

nonwindemos : $(DirDemos)\BindList.exe  \
              $(DirDemos)\SimpDemo.exe  \
              $(DirDemos)\DB2Isam.exe   \
              $(DirDemos)\Isam2DB.exe

# Note that OWDEMO is not automatically compiled: it requires the CCSKEYS
#      unit which is a bonus file.
# Note that DEWDEMO is not automatically compiled: it requires Data
#      Entry Workshop.
!if $d(UseBP7)
windemos : $(DirDemos)\BTWDemo.exe
!elif $d(UseDelphi)
windemos : $(DirDemos)\DelDemo.exe
!else
# Note that the TPCW command line compiler that comes with TPW 1.5 has great
#      difficulty compiling the BTWDEMO demo program without getting
#                   Error 1: Out of memory
#      Use TPW instead.
windemos : dummy
!endif


# ---------------------------------------------------- Assembly Language Source

!if $d(HaveAssembler)

$(DirBase)\NumKeys.obj: $(DirBase)\NumKeys.asm
  $(Assemble) $*;

!endif

# ---------------------------------------------------- Library Units

!if $d(UseDelphi) 
$(DirUnits)\DOSSupp.DCU : $(DirBase)\DOSSupp.PAS
 $(Compile) -e$(DirUnits) -u$(DirUnits) -i$(DirBase) -d$(TProOPro) DOSSupp

$(DirUnits)\BldNetTl.exe : $(DirNetTools)\BldNetTl.PAS \
                           $(DirUnits)\DOSSupp.DCU
 cd $(DirNetTools)
 $(Compile) -e$(DirUnits) -u$(DirUnits) -i$(DirBase) -d$(TProOPro) BldNetTl
 cd $(DirBase)
 erase $(DirUnits)\BldNetTl.EXE
!else  
$(DirUnits)\BldNetTl.exe : $(DirNetTools)\BldNetTl.PAS
 cd $(DirNetTools)
 $(Compile) -e$(DirUnits) -u$(DirUnits) -i$(DirBase) -d$(TProOPro) BldNetTl
 cd $(DirBase)
 erase $(DirUnits)\BldNetTl.EXE
!endif

$(DirUnits)\BldFiler.exe : $(DirBase)\BldFiler.PAS \
                           $(DirBase)\NumKeys.OBJ
 $(Compile) -e$(DirUnits) -u$(DirUnits) -i$(DirBase) -d$(TProOPro) BldFiler
 erase $(DirUnits)\BldFiler.EXE

$(DirUnits)\BldTools.exe : $(DirTools)\BldTools.PAS
 cd $(DirTools)
 $(Compile) -e$(DirUnits) -u$(DirUnits) -i$(DirBase) -d$(TProOPro) BldTools
 cd $(DirBase)
 erase $(DirUnits)\BldTools.EXE

$(DirUnits)\BldBrows.exe : $(DirBrowsers)\BldBrows.PAS
 cd $(DirBrowsers)
 !ifdef WantTV
 $(Compile) -e$(DirUnits) -u$(DirUnits) -i$(DirBase) -d$(TProOPro) -dWantTV BldBrows
 !else
 $(Compile) -e$(DirUnits) -u$(DirUnits) -i$(DirBase) -d$(TProOPro) BldBrows
 !endif
 cd $(DirBase)
 erase $(DirUnits)\BldBrows.EXE


# ------------------------------------------------------ Demo Programs

$(DirDemos)\SimpDemo.exe : $(DirUnits)\Filer.$(uext) \
                           $(DirUnits)\Browser.$(uext) \
                           $(DirDemos)\SimpDemo.PAS
 cd $(DirDemos)
 $(Compile) -u$(DirUnits) -i$(DirBase);$(DirBrowsers) $&
 cd $(DirBase)

$(DirDemos)\NetDemo.exe : $(DirUnits)\Filer.$(uext) \
                          $(DirUnits)\Browser.$(uext) \
                          $(DirDemos)\NetDemo.PAS
 cd $(DirDemos)
 $(Compile) -u$(DirUnits) -i$(DirBase);$(DirBrowsers) $&
 cd $(DirBase)

$(DirDemos)\OPIsDemo.exe : $(DirUnits)\Filer.$(uext) \
                           $(DirUnits)\OPBrow.$(uext) \
                           $(DirDemos)\OPIsDemo.PAS \
                           $(DirDemos)\OPIsMain.PAS \
                           $(DirDemos)\OPIsStuf.INC \
                           $(DirDemos)\FuncKeys.PAS \
                           $(DirDemos)\MkDrag.PAS
 cd $(DirDemos)
 $(Compile) -u$(DirUnits) -i$(DirBase);$(DirBrowsers) $&
 cd $(DirBase)

$(DirDemos)\TVIsDemo.exe : $(DirUnits)\Filer.$(uext) \
                           $(DirUnits)\TVBrows.$(uext) \
                           $(DirDemos)\TVIsDemo.PAS \
                           $(DirDemos)\TVIsStuf.INC \
                           $(DirDemos)\HeapChk.PAS
 cd $(DirDemos)
 $(Compile) -u$(DirUnits) -i$(DirBase);$(DirBrowsers) $&
 cd $(DirBase)

$(DirDemos)\OWDemo.exe : $(DirUnits)\Filer.$(uext) \
                         $(DirUnits)\WBrowser.$(uext) \
                         $(DirDemos)\OWDemo.PAS \
                         $(DirDemos)\OWDemo.RES \
                         $(DirDemos)\WRebld.PAS \
                         $(DirDemos)\WRebld.RES
 cd $(DirDemos)
 $(Compile) -u$(DirUnits) -i$(DirBase);$(DirBrowsers) $&
 cd $(DirBase)

$(DirDemos)\DEWDemo.exe : $(DirUnits)\Filer.$(uext) \
                          $(DirUnits)\WBrowser.$(uext) \
                          $(DirDemos)\DEWDemo.PAS \
                          $(DirDemos)\DEWDemo.RES
 cd $(DirDemos)
 $(Compile) -u$(DirUnits);c:\bp\units -i$(DirBase);$(DirBrowsers) $&
 cd $(DirBase)

$(DirDemos)\BTWDemo.exe : $(DirUnits)\Filer.$(uext) \
                          $(DirUnits)\WBrowser.$(uext) \
                          $(DirDemos)\BTWDemo.PAS \
                          $(DirDemos)\BTWDemo.RES \
                          $(DirDemos)\BTWStuff.INC
 cd $(DirDemos)
 $(Compile) -u$(DirUnits) -i$(DirBase);$(DirBrowsers) $&
 cd $(DirBase)

$(DirDemos)\DelDemo.exe : $(DirUnits)\Filer.$(uext) \
                          $(DirUnits)\FvcBrows.$(uext) \
                          $(DirDemos)\DelDemo.DPR \
                          $(DirDemos)\DelDemo1.PAS \
                          $(DirDemos)\DelDemo2.PAS \
                          $(DirDemos)\DelDemo3.PAS \
                          $(DirDemos)\DelDemo4.PAS \
                          $(DirDemos)\DelDemo5.PAS \
                          $(DirDemos)\DelDemo1.DFM \
                          $(DirDemos)\DelDemo2.DFM \
                          $(DirDemos)\DelDemo3.DFM \
                          $(DirDemos)\DelDemo4.DFM \
                          $(DirDemos)\DelDemo5.DFM 
 cd $(DirDemos)
 $(Compile) -u$(DirUnits);c:\bp\units -i$(DirBase);$(DirBrowsers) DelDemo.DPR
 cd $(DirBase)

$(DirDemos)\BigSort.exe : $(DirUnits)\MSort.$(uext) \
                          $(DirDemos)\BigSort.PAS
 cd $(DirDemos)
 $(Compile) -u$(DirUnits) -i$(DirBase) $&
 cd $(DirBase)

$(DirDemos)\NBChat.exe : $(DirUnits)\NetBios.$(uext) \
                         $(DirDemos)\NBChat.PAS
 cd $(DirDemos)
 $(Compile) -u$(DirUnits) -i$(DirBase) $&
 cd $(DirBase)

$(DirDemos)\NBSend.exe : $(DirUnits)\NetBios.$(uext) \
                         $(DirDemos)\NSSend.PAS
 cd $(DirDemos)
 $(Compile) -u$(DirUnits) -i$(DirBase) $&
 cd $(DirBase)

$(DirDemos)\NISend.exe : $(DirUnits)\NWIPXSPX.$(uext) \
                         $(DirDemos)\NISend.PAS
 cd $(DirDemos)
 $(Compile) -u$(DirUnits) -i$(DirBase) $&
 cd $(DirBase)

$(DirDemos)\NSSend.exe : $(DirUnits)\NWIPXSPX.$(uext) \
                         $(DirDemos)\NSSend.PAS
 cd $(DirDemos)
 $(Compile) -u$(DirUnits) -i$(DirBase) $&
 cd $(DirBase)

$(DirDemos)\MesExamp.exe : $(DirUnits)\NetBios.$(uext) \
                           $(DirUnits)\NWIPXSPX.$(uext) \
                           $(DirDemos)\MesExamp.PAS
 cd $(DirDemos)
 $(Compile) -u$(DirUnits) -i$(DirBase) $&
 cd $(DirBase)

$(DirDemos)\SPX2Way.exe : $(DirUnits)\NWIPXSPX.$(uext) \
                          $(DirDemos)\SPX2Way.PAS
 cd $(DirDemos)
 $(Compile) -u$(DirUnits) -i$(DirBase) $&
 cd $(DirBase)

$(DirDemos)\NetInfo.exe : $(DirUnits)\NWBase.$(uext) \
                          $(DirUnits)\NWConn.$(uext) \
                          $(DirUnits)\NWFile.$(uext) \
                          $(DirUnits)\NWMsg.$(uext) \
                          $(DirUnits)\NWTTS.$(uext) \
                          $(DirUnits)\NWPrint.$(uext) \
                          $(DirUnits)\NetBios.$(uext) \
                          $(DirDemos)\NetInfo.PAS
 cd $(DirDemos)
 $(Compile) -u$(DirUnits) -i$(DirBase) $&
 cd $(DirBase)

$(DirDemos)\Traffic.exe : $(DirUnits)\Filer.$(uext) \
                          $(DirDemos)\Traffic.PAS
 cd $(DirDemos)
 $(Compile) -u$(DirUnits) -i$(DirBase) $&
 cd $(DirBase)

$(DirDemos)\DB2Isam.exe : $(DirUnits)\DBImpExp.$(uext) \
                          $(DirDemos)\DB2Isam.PAS
 cd $(DirDemos)
 $(Compile) -u$(DirUnits) -i$(DirBase) $&
 cd $(DirBase)

$(DirDemos)\Isam2DB.exe : $(DirUnits)\DBImpExp.$(uext) \
                          $(DirDemos)\Isam2DB.PAS
 cd $(DirDemos)
 $(Compile) -u$(DirUnits) -i$(DirBase) $&
 cd $(DirBase)

$(DirDemos)\TTSFiler.exe : $(DirUnits)\Filer.$(uext) \
                           $(DirUnits)\NWFile.$(uext) \
                           $(DirUnits)\NWTTS.$(uext) \
                           $(DirDemos)\TTSFiler.PAS
 cd $(DirDemos)
 $(Compile) -u$(DirUnits) -i$(DirBase) $&
 cd $(DirBase)

$(DirDemos)\BindList.exe : $(DirUnits)\NWBase.$(uext) \
                           $(DirUnits)\NWBind.$(uext) \
                           $(DirDemos)\BindList.PAS
 cd $(DirDemos)
 $(Compile) -u$(DirUnits) -i$(DirBase) $&
 cd $(DirBase)
