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
* "Recharge Successful"
*
* Define DECRYPTON to activate the decrypter
*
* Created by CryptCon v~version~ on 11-01-1994 07:34:28 pm
*
* CryptCon created by Kevin G. McCoy
*
* ~notesend~
* ~nokeywords~
*
***************************************************************************
}

{$A+,B-,D+,E+,F-,G-,I-,L+,N-,O+,P-,Q-,R-,S-,T-,V-,X+,Y+}
UNIT SECON40;

INTERFACE
{Recharge Successful}

CONST
    SECON40N = 11196;
    SECON40P = 162;
    SECON40S : ARRAY[0..19] OF BYTE =
    (
        ORD('R') XOR 246,
        ORD('e') XOR 162,
        ORD('c') XOR 10,
        ORD('h') XOR 24,
        ORD('a') XOR 222,
        ORD('r') XOR 70,
        ORD('g') XOR 23,
        ORD('e') XOR 229,
        ORD(' ') XOR 3,
        ORD('S') XOR 107,
        ORD('u') XOR 8,
        ORD('c') XOR 103,
        ORD('c') XOR 140,
        ORD('e') XOR 236,
        ORD('s') XOR 128,
        ORD('s') XOR 212,
        ORD('f') XOR 182,
        ORD('u') XOR 204,
        ORD('l') XOR 182,
        ORD(0) XOR 168
    );


IMPLEMENTATION
END.
