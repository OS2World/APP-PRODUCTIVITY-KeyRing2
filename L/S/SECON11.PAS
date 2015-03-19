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
* "Dongle Security Compromised!"
*
* Define DECRYPTON to activate the decrypter
*
* Created by CryptCon on 09-28-1994 11:11:44 am
*
* CryptCon created by Kevin G. McCoy
*
* ~notesend~
* ~nokeywords~
*
***************************************************************************
}

{$A+,B-,D+,E+,F-,G-,I-,L+,N-,O+,P-,Q-,R-,S-,T-,V-,X+,Y+}
UNIT SECON11;

INTERFACE
    {Dongle Security Compromised!}

CONST
    SECON11N       = 34624;
    SECON11P       = 24;
    SECON11S       : ARRAY[0..28] OF BYTE =
    (
        ORD('D') XOR 103,
        ORD('o') XOR 96,
        ORD('n') XOR 12,
        ORD('g') XOR 177,
        ORD('l') XOR 26,
        ORD('e') XOR 180,
        ORD(' ') XOR 236,
        ORD('S') XOR 144,
        ORD('e') XOR 156,
        ORD('c') XOR 99,
        ORD('u') XOR 218,
        ORD('r') XOR 128,
        ORD('i') XOR 115,
        ORD('t') XOR 228,
        ORD('y') XOR 92,
        ORD(' ') XOR 89,
        ORD('C') XOR 38,
        ORD('o') XOR 239,
        ORD('m') XOR 198,
        ORD('p') XOR 159,
        ORD('r') XOR 224,
        ORD('o') XOR 172,
        ORD('m') XOR 117,
        ORD('i') XOR 241,
        ORD('s') XOR 251,
        ORD('e') XOR 77,
        ORD('d') XOR 3,
        ORD('!') XOR 76,
        ORD(0) XOR 160
        );


IMPLEMENTATION
END.
