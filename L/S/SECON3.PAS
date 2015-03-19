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
* Crypted Constant unit
*
* "?/"
*
* Define DECRYPTON to activate the decrypter
*
* Created by CryptCon on 09-28-1994 10:53:15 am
*
* CryptCon created by Kevin G. McCoy
*
* ~notesend~
* ~nokeywords~
*
***************************************************************************
}

{$A+,B-,D+,E+,F-,G-,I-,L+,N-,O+,P-,Q-,R-,S-,T-,V-,X+,Y+}
UNIT SECON3;

INTERFACE
    {?/}

CONST
    SECON3N        = 6108;
    SECON3P        = 68;
    SECON3S        : ARRAY[0..2] OF BYTE =
    (
        ORD('?') XOR 238,
        ORD('/') XOR 224,
        ORD(0) XOR 180
        );


IMPLEMENTATION
END.
