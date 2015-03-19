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
* "Call customer support!"
*
* Define DECRYPTON to activate the decrypter
*
* Created by CryptCon v~version~ on 11-01-1994 04:35:22 pm
*
* CryptCon created by Kevin G. McCoy
*
* ~notesend~
* ~nokeywords~
*
***************************************************************************
}
{$A+,B-,D+,E+,F-,G-,I-,L+,N-,O+,P-,Q-,R-,S-,T-,V-,X+,Y+}
UNIT SECON38;

INTERFACE

{Call customer support!}

CONST
    SECON38N = 25347;
    SECON38P = 221;
    SECON38S : ARRAY[0..22] OF BYTE =
    (
        ORD('C') XOR 191,
        ORD('a') XOR 126,
        ORD('l') XOR 115,
        ORD('l') XOR 195,
        ORD(' ') XOR 40,
        ORD('c') XOR 192,
        ORD('u') XOR 167,
        ORD('s') XOR 156,
        ORD('t') XOR 22,
        ORD('o') XOR 124,
        ORD('m') XOR 54,
        ORD('e') XOR 75,
        ORD('r') XOR 161,
        ORD(' ') XOR 85,
        ORD('s') XOR 183,
        ORD('u') XOR 89,
        ORD('p') XOR 15,
        ORD('p') XOR 165,
        ORD('o') XOR 152,
        ORD('r') XOR 128,
        ORD('t') XOR 48,
        ORD('!') XOR 135,
        ORD(0) XOR 172
    );


IMPLEMENTATION
END.
