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
* "Enter your name"
*
* Define DECRYPTON to activate the decrypter
*
* Created by CryptCon v~version~ on 11-01-1994 04:35:14 pm
*
* CryptCon created by Kevin G. McCoy
*
* ~notesend~
* ~nokeywords~
*
***************************************************************************
}
{$A+,B-,D+,E+,F-,G-,I-,L+,N-,O+,P-,Q-,R-,S-,T-,V-,X+,Y+}
UNIT SECON37;

INTERFACE

{Enter your name}

CONST
    SECON37N = 39006;
    SECON37P = 237;
    SECON37S : ARRAY[0..15] OF BYTE =
    (
        ORD('E') XOR 236,
        ORD('n') XOR 249,
        ORD('t') XOR 65,
        ORD('e') XOR 9,
        ORD('r') XOR 172,
        ORD(' ') XOR 17,
        ORD('y') XOR 157,
        ORD('o') XOR 92,
        ORD('u') XOR 70,
        ORD('r') XOR 98,
        ORD(' ') XOR 0,
        ORD('n') XOR 165,
        ORD('a') XOR 35,
        ORD('m') XOR 254,
        ORD('e') XOR 42,
        ORD(0) XOR 127
    );


IMPLEMENTATION
END.
