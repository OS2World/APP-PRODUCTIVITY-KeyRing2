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
* "Invalid Dongle Header"
*
* Define DECRYPTON to activate the decrypter
*
* Created by CryptCon on 09-28-1994 11:11:58 am
*
* CryptCon created by Kevin G. McCoy
*
* ~notesend~
* ~nokeywords~
*
***************************************************************************
}
{$A+,B-,D+,E+,F-,G-,I-,L+,N-,O+,P-,Q-,R-,S-,T-,V-,X+,Y+}
{$M 65000,0,655360}
UNIT SECON12;

INTERFACE
    {Invalid Dongle Header}

CONST
    SECON12N       = 12056;
    SECON12P       = 213;
    SECON12S       : ARRAY[0..21] OF BYTE =
    (
        ORD('I') XOR 133,
        ORD('n') XOR 86,
        ORD('v') XOR 181,
        ORD('a') XOR 236,
        ORD('l') XOR 176,
        ORD('i') XOR 141,
        ORD('d') XOR 18,
        ORD(' ') XOR 151,
        ORD('D') XOR 67,
        ORD('o') XOR 232,
        ORD('n') XOR 160,
        ORD('g') XOR 241,
        ORD('l') XOR 117,
        ORD('e') XOR 93,
        ORD(' ') XOR 212,
        ORD('H') XOR 205,
        ORD('e') XOR 73,
        ORD('a') XOR 234,
        ORD('d') XOR 52,
        ORD('e') XOR 211,
        ORD('r') XOR 12,
        ORD(0) XOR 81
        );


IMPLEMENTATION
END.
