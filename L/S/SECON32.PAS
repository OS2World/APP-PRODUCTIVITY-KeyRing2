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
* "Full Name :"
*
* Define DECRYPTON to activate the decrypter
*
* Created by CryptCon v~version~ on 11-01-1994 04:16:32 pm
*
* CryptCon created by Kevin G. McCoy
*
* ~notesend~
* ~nokeywords~
*
***************************************************************************
}

{$A+,B-,D+,E+,F-,G-,I-,L+,N-,O+,P-,Q-,R-,S-,T-,V-,X+,Y+}
UNIT SECON32;

INTERFACE

{Full Name :}

CONST
    SECON32N = 8464;
    SECON32P = 209;
    SECON32S : ARRAY[0..11] OF BYTE =
    (
        ORD('F') XOR 73,
        ORD('u') XOR 137,
        ORD('l') XOR 71,
        ORD('l') XOR 94,
        ORD(' ') XOR 247,
        ORD('N') XOR 225,
        ORD('a') XOR 136,
        ORD('m') XOR 136,
        ORD('e') XOR 116,
        ORD(' ') XOR 122,
        ORD(':') XOR 68,
        ORD(0) XOR 204
    );


IMPLEMENTATION
END.
