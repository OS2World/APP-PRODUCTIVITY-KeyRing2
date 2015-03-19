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
* "ruHxpxrxdmabiVrl"
*
* Define DECRYPTON to activate the decrypter
*
* Created by CryptCon on 09-28-1994 10:54:36 am
*
* CryptCon created by Kevin G. McCoy
*
* ~notesend~
* ~nokeywords~
*
***************************************************************************
}
{$A+,B-,D+,E+,F-,G-,I-,L+,N-,O+,P-,Q-,R-,S-,T-,V-,X+,Y+}
UNIT SECON6;

INTERFACE

    {ruHxpxrxdmabiVrl}

CONST
    SECON6N        = 26266;
    SECON6P        = 203;
    SECON6S        : ARRAY[0..16] OF BYTE =
    (
        ORD('r') XOR 242,
        ORD('u') XOR 209,
        ORD('H') XOR 70,
        ORD('x') XOR 9,
        ORD('p') XOR 174,
        ORD('x') XOR 118,
        ORD('r') XOR 129,
        ORD('x') XOR 109,
        ORD('d') XOR 44,
        ORD('m') XOR 5,
        ORD('a') XOR 40,
        ORD('b') XOR 208,
        ORD('i') XOR 171,
        ORD('V') XOR 103,
        ORD('r') XOR 217,
        ORD('l') XOR 61,
        ORD(0) XOR 58
        );


IMPLEMENTATION
END.
