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
* "Challenge :"
*
* Define DECRYPTON to activate the decrypter
*
* Created by CryptCon v~version~ on 11-01-1994 04:16:39 pm
*
* CryptCon created by Kevin G. McCoy
*
* ~notesend~
* ~nokeywords~
*
***************************************************************************
}

{$A+,B-,D+,E+,F-,G-,I-,L+,N-,O+,P-,Q-,R-,S-,T-,V-,X+,Y+}
UNIT SECON33;

INTERFACE

{Challenge :}

CONST
    SECON33N = 23254;
    SECON33P = 194;
    SECON33S : ARRAY[0..11] OF BYTE =
    (
        ORD('C') XOR 118,
        ORD('h') XOR 230,
        ORD('a') XOR 24,
        ORD('l') XOR 38,
        ORD('l') XOR 171,
        ORD('e') XOR 30,
        ORD('n') XOR 30,
        ORD('g') XOR 14,
        ORD('e') XOR 54,
        ORD(' ') XOR 40,
        ORD(':') XOR 22,
        ORD(0) XOR 99
    );


IMPLEMENTATION
END.
