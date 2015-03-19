{*********************************************************}
{*                  BTDEFINE.INC 5.51                    *}
{*      Copyright (c) TurboPower Software 1989,1994      *}
{*                 All rights reserved.                  *}
{*********************************************************}

{---Conditional defines that affect B-Tree Filer units---}


{.$DEFINE UseFilerDLL}
{-Activate or deactivate the use of the B-Tree Filer DLL and its
  import units.}


{===B-Tree Filer DLL specific defines================================}
{$IFDEF UseFilerDLL}

{.$DEFINE NoNet}
{-Activate or deactivate the use of network support under the DLL.}

{$ENDIF}
{====================================================================}


{===Statically linked B-Tree Filer defines===========================}
{$IFNDEF UseFilerDLL}

{$DEFINE NoNet}
{.$DEFINE Novell}
{.$DEFINE MsNet}
{-Valid network interfaces. One or more must be defined, but NoNet
  may not be selected except by itself.}

{$IFDEF Novell}
{$DEFINE SupportVLM}
{-If compiling for Novell NetWare, defining SupportVLM will link in
  the relevant NWXXXX units to support VLMs as well as NETX. This is
  not an option for the DLL.}
{$ENDIF}

{$IFNDEF DPMI}
{$IFNDEF Windows}
{$DEFINE UseEMSHeap}
{-Adds code to the FILER unit to store page buffers in EMS in real
  mode only. EMS cannot be used under Windows or DPMI.}
{$ENDIF}
{$ENDIF}

{$IFDEF UseEMSHeap}
{.$DEFINE EMSDisturbance}
{-Adds code to save and restore the EMS page mapping.}
{$ENDIF}

{.$DEFINE InitAllUnits}
{-Activate this define to cause all B-Tree Filer units to have an
  initialization block, even if only an empty one. This works around
  a bug in some early versions of Borland's Turbo Debugger.}

{-Note: the defines for DebugEMSHeap, NoErrorCheckEMSHeap,
        ManualInitEMSHeap, UseTPEMS, and UseOPEMS have been moved into
        EMSHEAP.PAS, which is the only unit they affect.}

{$ENDIF}
{====================================================================}


{===Common defines between static/dynamic linked B-Tree Filer========}

{$IFNDEF NoNet}
{.$DEFINE LockBeforeRead}
{-Automatically locks any file section before reading it, then
  unlocks. May be needed to avoid a bug in some versions of the
  NetWare NETX shell.}
{$ENDIF}

{$DEFINE LengthByteKeys}
{.$DEFINE AsciiZeroKeys}
{-One of LengthByteKeys or AsciiZeroKeys must be defined, but not
  both. LengthByteKeys causes B-Tree Filer to store Turbo Pascal style
  strings in the index file. AsciiZeroKeys causes B-Tree Filer to
  store C-style ASCIIZ strings in the index file.}

{.$DEFINE UseTPCRT}
{.$DEFINE UseOPCRT}
{-Either UseTPCRT or UseOPCRT may be defined, but not both. These
  defines affect the BROWSER unit only (and programs using BROWSER,
  for example NETDEMO). Don't activate either one if the program uses
  neither the TPCRT nor OPCRT units from Turbo Professional and
  Object Professional, respectively.}

{====================================================================}

(********************************************************************)
(********************************************************************)
{Don't change anything beyond this point}

{The following define allows extensions to B-Tree Filer to detect the new
 syntax of versions 5.2 and later.}

{$DEFINE BTree52}

{The following define allows extensions to B-Tree Filer to detect the new
 syntax of versions 5.4 and later.}

{$DEFINE BTree54}

{--Define whether a DPMI or Windows compiler is used}
  {$IFDEF Windows}
    {$DEFINE DPMIOrWnd}
  {$ENDIF}
  {$IFDEF DPMI}
    {$DEFINE DPMIOrWnd}
  {$ENDIF}

{--Define the used heap type}
  {$IFNDEF DPMIOrWnd}
    {$DEFINE Heap6}
    {$IFDEF UseFilerDLL}
      !! ERROR: Real mode targets are not supported with the DLL
    {$ENDIF}
    {$IFDEF Ver50}
      {$UNDEF Heap6}
    {$ENDIF}
    {$IFDEF Ver55}
      {$UNDEF Heap6}
    {$ENDIF}
  {$ENDIF}

{--Define whether overlays can be allowed}
  {$IFDEF MSDOS}
    {$DEFINE CanAllowOverlays}
  {$ELSE}
    {$UNDEF CanAllowOverlays}
  {$ENDIF}

{--Define whether the overflow check option can be set}
  {$UNDEF CanSetOvrflowCheck}
  {$IFNDEF Ver10}
    {$IFNDEF Ver15}
      {$IFNDEF Ver50}
        {$IFNDEF Ver55}
          {$IFNDEF Ver60}
            {$DEFINE CanSetOvrflowCheck}
          {$ENDIF}
        {$ENDIF}
      {$ENDIF}
    {$ENDIF}
  {$ENDIF}

{--Test the usage of Turbo Pascal 4.0}
  {$IFNDEF Windows}
    {$IFDEF Ver40}
      !! ERROR: Turbo Pascal 4.0 is not supported
    {$ENDIF}
  {$ENDIF}

{--Test the definition of the net interfaces}
{$IFNDEF UseFilerDLL}
  {$IFDEF Novell}
    {$DEFINE RealNetDefined}
  {$ENDIF}
  {$IFDEF MsNet}
    {$DEFINE RealNetDefined}
  {$ENDIF}

  {$IFDEF NoNet}
    {$IFDEF RealNetDefined}
      !! ERROR: You may not define NoNet and any other Net simultaneously
    {$ENDIF}
  {$ELSE}
    {$IFNDEF RealNetDefined}
      !! ERROR: You must define either NoNet or at least one real network
    {$ENDIF}
  {$ENDIF}
  {$UNDEF RealNetDefined}
{$ENDIF}

{--Test the XXKeys defines}
  {$IFDEF LengthByteKeys}
    {$IFDEF ASCIIZeroKeys}
      !! ERROR: You may not define both LengthByteKeys and AsciiZeroKeys
    {$ENDIF}
  {$ELSE}
    {$IFNDEF ASCIIZeroKeys}
      !! ERROR: You must define either LengthByteKeys or AsciiZeroKeys
    {$ENDIF}
  {$ENDIF}

{--Test the UseXXCrt defines}
  {$IFDEF UseTPCRT}
    {$IFDEF UseOPCRT}
      !! ERROR: You may not define both UseTPCrt and UseOPCrt
    {$ENDIF}
  {$ENDIF}

{--Test the FILER.MAK directives}
  {$IFDEF TProOnly}
    {$IFNDEF UseTPCrt}
      !! ERROR: You must define UseTPCRT if compiling with TPro
    {$ENDIF}
  {$ENDIF}
  {$IFDEF OProOnly}
    {$IFNDEF UseOPCrt}
      !! ERROR: You must define UseOPCRT if compiling with OPro
    {$ENDIF}
  {$ENDIF}
