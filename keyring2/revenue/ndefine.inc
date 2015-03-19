{ Filename:~modname~    Version:~version~     Date:~MNAme~ ~day~, ~fullyear~  ~time~
*
*
* Modifications
* -------------
*
* Version   Date     Time    Programmer     Description
* ~log~
*
*
* ~nokeywords~
*
* Description
* -----------
* Purpose:
*
*
*
****************************************************************************

}

{ Activate or deactivate various product specific NCommandProcessor    }
{ features.  Activation of unused command processor features will result }
{ in unnecessary DGROUP usage!                                           }

{$DEFINE USINGBROWSE}
{.$DEFINE USINGCAL}
{.$DEFINE USINGCALC}
{$DEFINE USINGDIALOG}
{$DEFINE USINGEDIT}
{$DEFINE USINGEDITOR}
{$DEFINE USINGENTRY}
{$DEFINE USINGHELP}
{.$DEFINE USINGMACED}
{$DEFINE USINGMEMO}
{$DEFINE USINGMENU}
{$DEFINE USINGPICK}
{.$DEFINE USINGQKREF}
{.$DEFINE USINGSIMPEDIT}
{$DEFINE USINGSELECT}

{turn on buffered encryption methods}
{$DEFINE BUFFEREDCRYPT}
{$DEFINE PLQF_NOHOLES}

{.$DEFINE AllowIsamErrorMessages}
{$DEFINE AllowOPROErrorMessages}
{.$DEFINE AllowAproErrorMessages}
{.$DEFINE AllowFilerErrorMessages}

{************************************************************************}
{************************************************************************}
