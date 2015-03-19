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
* "Enter user challenge"
*
* Define DECRYPTON to activate the decrypter
*
* Created by CryptCon v~version~ on 11-01-1994 04:56:45 pm
*
* CryptCon created by Kevin G. McCoy
*
* ~notesend~
* ~nokeywords~
*
***************************************************************************
}
{$A+,B-,D+,E+,F-,G-,I-,L+,N-,O+,P-,Q-,R-,S-,T-,V-,X+,Y+}
UNIT SECON39;

INTERFACE

{Enter user challenge}

CONST
    SECON39N = 5809;
    SECON39P = 244;
    SECON39S : ARRAY[0..20] OF BYTE =
    (
        ORD('E') XOR 188,
        ORD('n') XOR 102,
        ORD('t') XOR 37,
        ORD('e') XOR 58,
        ORD('r') XOR 119,
        ORD(' ') XOR 186,
        ORD('u') XOR 28,
        ORD('s') XOR 107,
        ORD('e') XOR 50,
        ORD('r') XOR 236,
        ORD(' ') XOR 75,
        ORD('c') XOR 160,
        ORD('h') XOR 83,
        ORD('a') XOR 181,
        ORD('l') XOR 20,
        ORD('l') XOR 254,
        ORD('e') XOR 103,
        ORD('n') XOR 206,
        ORD('g') XOR 93,
        ORD('e') XOR 199,
        ORD(0) XOR 68
    );


IMPLEMENTATION
END.
