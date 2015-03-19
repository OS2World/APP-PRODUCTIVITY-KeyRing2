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
* "I/"
*
* Define DECRYPTON to activate the decrypter
*
* Created by CryptCon on 09-28-1994 10:53:10 am
*
* CryptCon created by Kevin G. McCoy
*
* ~notesend~
* ~nokeywords~
*
***************************************************************************
}

{$A+,B-,D+,E+,F-,G-,I-,L+,N-,O+,P-,Q-,R-,S-,T-,V-,X+,Y+}
UNIT SECON2;

INTERFACE

    {I/}

CONST
    SECON2N        = 39452;
    SECON2P        = 79;
    SECON2S        : ARRAY[0..2] OF BYTE =
    (
        ORD('I') XOR 79,
        ORD('/') XOR 82,
        ORD(0) XOR 79
        );


IMPLEMENTATION
END.
