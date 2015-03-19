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
* "NewsMaker Systems "
*
* Define DECRYPTON to activate the decrypter
*
* Created by CryptCon on 09-28-1994 11:11:15 am
*
* CryptCon created by Kevin G. McCoy
*
* ~notesend~
* ~nokeywords~
*
***************************************************************************
}
{$A+,B-,D+,E+,F-,G-,I-,L+,N-,O+,P-,Q-,R-,S-,T-,V-,X+,Y+}
UNIT SECON9;

INTERFACE
    {NewsMaker Systems }

CONST
    SECON9N        = 395;
    SECON9P        = 183;
    SECON9S        : ARRAY[0..18] OF BYTE =
    (
        ORD('N') XOR 211,
        ORD('e') XOR 8,
        ORD('w') XOR 116,
        ORD('s') XOR 76,
        ORD('M') XOR 115,
        ORD('a') XOR 247,
        ORD('k') XOR 224,
        ORD('e') XOR 254,
        ORD('r') XOR 205,
        ORD(' ') XOR 26,
        ORD('S') XOR 141,
        ORD('y') XOR 122,
        ORD('s') XOR 227,
        ORD('t') XOR 252,
        ORD('e') XOR 230,
        ORD('m') XOR 116,
        ORD('s') XOR 95,
        ORD(' ') XOR 190,
        ORD(0) XOR 248
        );


IMPLEMENTATION
END.
