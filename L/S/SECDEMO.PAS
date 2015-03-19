{***************************************************************************
* Filename: ~modname~
* Version:  ~version~
* Date:     ~date~ @ ~time~
* Group:    ~group~
* Release:  ~release~
* ----------------------------
*
* Modifications
* -------------
*
* Version   Date     Time    Programmer   Description
* ~log~
*
*
* ~notes~
* Description
* -----------
* obsolete demo program
*
*
* ~notesend~
* ~nokeywords~
*
****************************************************************************

}
{$A+,B-,D+,E+,F+,G+,I+,L+,N-,O+,P-,Q+,R+,S+,T-,V-,X+,Y+}
{$M 65000,0,655360}
PROGRAM SECDEMO;

USES
    SecOvr,
    ApMisc,
    Banner2,
    B_NEN,
    CmdLin,
    Crc,
    CRT,
    Dos,
    Dpmi,
    EGlobal,
    ELines,
    FDialog,
    NetBind,
    NetSema,
    NetWare,
    NWIPXSPX,
    OpAbsFld,
    OpAbsWin,
    OpAsciiz,
    OpBCD,
    OpCmd,
    OpCol16,
    OpColor,
    OpConst,
    OpCrt,
    OpCtrl,
    OpDate,
    OpDialog,
    OpDir,
    OpDos,
    OpDrag,
    OpEdit,
    OpEditor,
    OpEms,
    OpEntry,
    OpFEdit,
    OpField,
    OpFrame,
    OpInline,
    OpInt,
    OpKey,
    OpMemo,
    OpMenu,
    OpMouse,
    OpPick,
    OpRoot,
    OpSelect,
    OpString,
    OpWindow,
    Printer,
    QCmdDsp,
    Qcursor,
    QDrives,
    QFiles,
    QForms,
    QFRMDict,
    QGlobal,
    QHdrRec,
    QHeap,
    QInput,
    QLOG,
    QNENINI,
    QNetMsg,
    QNovell,
    QScreen,
    QScrF,
    QScrV,
    QTCode,
    QUpTime,
    R_Glo,
    SDEmoent,
    SEBUFF,
    SECHALNG,
    SECONST,
    SECONT,
    SECRPTLO,
    SEDONGLE,
    SEQUERY,
    SESECURE,
    Strings,
    UBOOT,
    UColors,
    UCPUID,
    UDIALOG,
    UDirec,
    UEdit,
    UERROR,
    UFkey,
    UGLOBAL,
    UINI,
    UIpxSpx,
    UKey,
    ULanguag,
    ULIB,
    UMENU,
    UMsg,
    UReboot,
    Urgent,
    URLINE,
    USpxChk,
    USpxDat,
    USPXGlo,
    USpxMsg,
    UTIAM,
    UTOOINI,
    UTPMWIN,
    UTTIMDAT,
    UWindow;

    {$O ApMisc}
    {$O Banner2}
    {$O B_NEN}
    {$O CmdLin}
    {$O Crc}
    {$O Dos}
    {$O EGlobal}
    {$O ELines}
    {$O FDialog}
    {$O NetBind}
    {$O NetSema}
    {$O NetWare}
    {$O OpAbsFld}
    {$O OpAbsWin}
    {$O OpAsciiz}
    {$O OpBCD}
    {$O OpCtrl}
    {$O OpDate}
    {$O OpDialog}
    {$O OpDir}
    {$O OpDos}
    {$O OpEdit}
    {$O OpEditor}
    {$O OpEntry}
    {$O OpFEdit}
    {$O OpField}
    {$O OpFrame}
    {$O OpMemo}
    {$O OpMenu}
    {$O OpPick}
    {$O OpRoot}
    {$O OpSelect}
    {$O OpWindow}
    {$O QCmdDsp}
    {$O Qcursor}
    {$O QDrives}
    {$O QFiles}
    {$O QForms}
    {$O QFRMDict}
    {$O QGlobal}
    {$O QHdrRec}
    {$O QInput}
    {$O QLOG}
    {$O QNENINI}
    {$O QNetMsg}
    {$O QNovell}
    {$O QScreen}
    {$O QScrF}
    {$O QScrV}
    {$O QTCode}
    {$O QUpTime}
    {$O R_Glo}
    {$O SDEmoent}
    {$O SEBUFF}
    {$O SECDEMO}
    {$O SECHALNG}
    {$O SECONST}
    {$O SECONT}
    {$O SECRPTLO}
    {$O SEDONGLE}
    {$O SEQUERY}
    {$O SESECURE}
    {$O Uboot}
    {$O UColors}
    {$O UDIALOG}
    {$O UDirec}
    {$O UEdit}
    {$O UERROR}
    {$O UFkey}
    {$O UGLOBAL}
    {$O UINI}
    {$O UIPXSPX}
    {$O UKey}
    {$O ULanguag}
    {$O ULIB}
    {$O UMENU}
    {$O UMsg}
    {$O Urgent}
    {$O URLINE}
    {$O USPXCHK}
    {$O USpxMsg}
    {$O UTIAM}
    {$O UTOOINI}
    {$O UTPMWIN}
    {$O UTTIMDAT}
    {$O UWindow}
BEGIN
    DemoEntry;
END.
