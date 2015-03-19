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
* "R/"
*
* Define DECRYPTON to activate the decrypter
*
* Created by CryptCon on 09-28-1994 10:53:18 am
*
* CryptCon created by Kevin G. McCoy
*
* ~notesend~
* ~nokeywords~
*
***************************************************************************
}

{$A+,B-,D+,E+,F-,G-,I-,L+,N-,O+,P-,Q-,R-,S-,T-,V-,X+,Y+}
UNIT SECON4;

INTERFACE

    {R/}

CONST
    SECON4N        = 48168;
    SECON4P        = 214;
    SECON4S        : ARRAY[0..2] OF BYTE =
    (
        ORD('R') XOR 87,
        ORD('/') XOR 86,
        ORD(0) XOR 29
        );


IMPLEMENTATION
END.
