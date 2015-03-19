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
* "Dongle nearing end of R/W lifetime!"
*
* Define DECRYPTON to activate the decrypter
*
* Created by CryptCon v~version~ on 09-30-1994 05:42:02 pm
*
* CryptCon created by Kevin G. McCoy
*
* ~notesend~
* ~nokeywords~
*
***************************************************************************
}
{$A+,B-,D+,E+,F-,G-,I-,L+,N-,O+,P-,Q-,R-,S-,T-,V-,X+,Y+}
UNIT SECON28;

INTERFACE

    {Dongle nearing end of R/W lifetime!}

CONST
    SECON28N       = 23195;
    SECON28P       = 248;
    SECON28S       : ARRAY[0..35] OF BYTE =
    (
        ORD('D') XOR 34,
        ORD('o') XOR 201,
        ORD('n') XOR 76,
        ORD('g') XOR 70,
        ORD('l') XOR 26,
        ORD('e') XOR 72,
        ORD(' ') XOR 230,
        ORD('n') XOR 154,
        ORD('e') XOR 53,
        ORD('a') XOR 201,
        ORD('r') XOR 95,
        ORD('i') XOR 130,
        ORD('n') XOR 44,
        ORD('g') XOR 126,
        ORD(' ') XOR 60,
        ORD('e') XOR 74,
        ORD('n') XOR 238,
        ORD('d') XOR 217,
        ORD(' ') XOR 95,
        ORD('o') XOR 81,
        ORD('f') XOR 83,
        ORD(' ') XOR 16,
        ORD('R') XOR 93,
        ORD('/') XOR 37,
        ORD('W') XOR 65,
        ORD(' ') XOR 248,
        ORD('l') XOR 184,
        ORD('i') XOR 85,
        ORD('f') XOR 161,
        ORD('e') XOR 57,
        ORD('t') XOR 185,
        ORD('i') XOR 249,
        ORD('m') XOR 141,
        ORD('e') XOR 122,
        ORD('!') XOR 70,
        ORD(0) XOR 212
        );


IMPLEMENTATION
END.
