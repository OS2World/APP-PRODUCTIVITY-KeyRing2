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
* "Recharge Failure"
*
* Define DECRYPTON to activate the decrypter
*
* Created by CryptCon v~version~ on 11-01-1994 07:34:42 pm
*
* CryptCon created by Kevin G. McCoy
*
* ~notesend~
* ~nokeywords~
*
***************************************************************************
}

{$A+,B-,D+,E+,F-,G-,I-,L+,N-,O+,P-,Q-,R-,S-,T-,V-,X+,Y+}
UNIT SECON41;

INTERFACE

{Recharge Failure}

CONST
    SECON41N = 2756;
    SECON41P = 221;
    SECON41S : ARRAY[0..16] OF BYTE =
    (
        ORD('R') XOR 166,
        ORD('e') XOR 69,
        ORD('c') XOR 194,
        ORD('h') XOR 210,
        ORD('a') XOR 243,
        ORD('r') XOR 59,
        ORD('g') XOR 52,
        ORD('e') XOR 249,
        ORD(' ') XOR 126,
        ORD('F') XOR 150,
        ORD('a') XOR 75,
        ORD('i') XOR 179,
        ORD('l') XOR 37,
        ORD('u') XOR 214,
        ORD('r') XOR 21,
        ORD('e') XOR 220,
        ORD(0) XOR 14
    );


IMPLEMENTATION
END.
