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
* This module/object finds the label alias table in the Key file and assigns
* the decrypted strings to a lookup table.  The label lookup table is used to
* locate the desired INI file values, when this object is queried.
*
* The indirect lookup of INI file values makes hacking value assignment code
* much more difficult.
*
*
* ~notesend~
* ~nokeywords~
*
****************************************************************************

}
UNIT SEQUERY;

    {$V-}
    {$A+,B-,D+,E+,F-,G+,I-,L+,N-,O+,P-,Q-,T-,V-,X+,Y+}

    (****************************************************************************)

INTERFACE
USES
    Dos,
    SECONT,
    SECRPTLO,
    OpRoot,
    Strings;

TYPE

    {enumerated list of possible key.ini file var labels and sections.}
    {add new ones to the end of the list, just before EBAD.           }
    {Make a corresponding change to the alias list at the top of      }
    {the key.ini file                                                 }

    SecLabelT      = (EPROD,      {products}
                      ESERV,      {novell servers}
                      EDONG,      {dongles}
                      EGLOB,      {globals product and platform}
                      EFEAT,      {product feature switches}
                      EUSER,      {user lists}
                      ESTATID,    {station id}
                      EMAXWS,     {max workstations}
                      ESTATLOC,   {station location}
                      ESTATLIC,   {station license}
                      EDROPDEAD,  {drop dead date}
                      EDATELOCK,  {exe date must be before this date}
                      EPHANTOM,   {dont count these people in WS count}
                      EBATT,      {"battery" variables}
                      ERCHRG,     {last recharge date}
                      ELASTUSE,   {last used date}
                      EMAXCHRG,   {charge duration in days}
                      EBATTWARN,  {days warning to user before charge fail}
                      EMINSEC,    {minimum EMAIL security}
                      EMAXSEC,    {maximum EMAIL security}
                      ENOUSEBAT,  {don't use battery charge}
                      EBAD);      {Dont move EBAD; add enums just before it}


    SecStatT       = (EBADSEC, EDEMOSEC, EWARNSEC, EGOODSEC);

    SecQueryP      = ^SecQuery;
    SecQuery       = OBJECT(ContextNode)
                         ProdName       : STRING;

                         CONSTRUCTOR Init(FName,
                                          CryptID,
                                          PrivKey,
                                          MyProdName     : STRING;
                                          KeyLength      : WORD;
                                          CryptVer       : LONGINT;
                                          VAR Comment    : STRING);
                         DESTRUCTOR Done; VIRTUAL;

                             {returns trailing colon}
                         FUNCTION GetLabel(LT : SecLabelT) : STRING;

                             {no trailing colon}
                         FUNCTION GetLabelNC(LT : SecLabelT) : STRING;

                     PRIVATE

                         TCP            : TextCryptPtr;
                         Tags           : ContextNodeP;
                     END;
    (****************************************************************************)

IMPLEMENTATION


USES
    UTIAM,
    OpConst,
    OpString,
    SECONST,
    UERROR,
    ULIB;

    (****************************************************************************)

    CONSTRUCTOR SecQuery.Init(FName,
                              CryptID,
                              PrivKey,
                              MyProdName     : STRING;
                              KeyLength      : WORD;
                              CryptVer       : LONGINT;
                              VAR Comment    : STRING);
    VAR
        Strg           : STRING;
    BEGIN

        NEW(TCP, ReadInit(FName, CryptID, PrivKey, KeyLength, CryptVer, Comment));

        IF TCP = NIL THEN
            FAIL;

        IF NOT ContextNode.Init('>', TCP, 1) THEN
            FAIL;

        DISPOSE(TCP, Done);
        TCP := NIL;

        Tags := FindNode(DecodeStrg(SECON47S, SECON47N, SECON47P));
        IF Tags = NIL THEN BEGIN
            InitStatus := epFatal + ecBadFormat;
            FAIL;
        END;

        ProdName := MyProdName + ':';

    END;

    (****************************************************************************)

    DESTRUCTOR SecQuery.Done;
    BEGIN
        (*DISPOSE(Tags, Done);*)
        ContextNode.Done;
    END;

    (****************************************************************************)

    FUNCTION SecQuery.GetLabelNC(LT : SecLabelT) : STRING;
    BEGIN
        GetLabelNC := Tags^.GetNthVar(ORD(LT) + 1);
    END;

    (****************************************************************************)

    FUNCTION SecQuery.GetLabel(LT : SecLabelT) : STRING;
    BEGIN
        GetLabel := GetLabelNC(LT) + ':';
    END;

    (****************************************************************************)

    {unit initialization}

END.                              {of unit sequery}
(****************************************************************************)
(****************************************************************************)


