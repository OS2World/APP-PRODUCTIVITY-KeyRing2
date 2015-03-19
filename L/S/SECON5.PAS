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
* "W/"
*
* Define DECRYPTON to activate the decrypter
*
* Created by CryptCon on 09-28-1994 10:53:27 am
*
* CryptCon created by Kevin G. McCoy
*
* ~notesend~
* ~nokeywords~
*
***************************************************************************
}
{$A+,B-,D+,E+,F-,G-,I-,L+,N-,O+,P-,Q-,R-,S-,T-,V-,X+,Y+}
UNIT SECON5;

INTERFACE

    {W/}

CONST
    SECON5N        = 29579;
    SECON5P        = 90;
    SECON5S        : ARRAY[0..2] OF BYTE =
    (
        ORD('W') XOR 117,
        ORD('/') XOR 145,
        ORD(0) XOR 86
        );


IMPLEMENTATION
END.
