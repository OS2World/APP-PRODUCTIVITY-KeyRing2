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
* "yPpbpcpqapxysjhr"
*
* Define DECRYPTON to activate the decrypter
*
* Created by CryptCon on 09-28-1994 10:55:11 am
*
* CryptCon created by Kevin G. McCoy
*
* ~notesend~
* ~nokeywords~
*
***************************************************************************
}
{$A+,B-,D+,E+,F-,G-,I-,L+,N-,O+,P-,Q-,R-,S-,T-,V-,X+,Y+}

UNIT SECON7;

INTERFACE
    {yPpbpcpqapxysjhr}

CONST
    SECON7N        = 47093;
    SECON7P        = 72;
    SECON7S        : ARRAY[0..16] OF BYTE =
    (
        ORD('y') XOR 141,
        ORD('P') XOR 211,
        ORD('p') XOR 237,
        ORD('b') XOR 244,
        ORD('p') XOR 135,
        ORD('c') XOR 219,
        ORD('p') XOR 215,
        ORD('q') XOR 195,
        ORD('a') XOR 133,
        ORD('p') XOR 22,
        ORD('x') XOR 19,
        ORD('y') XOR 25,
        ORD('s') XOR 83,
        ORD('j') XOR 91,
        ORD('h') XOR 229,
        ORD('r') XOR 139,
        ORD(0) XOR 68
        );


IMPLEMENTATION
END.
