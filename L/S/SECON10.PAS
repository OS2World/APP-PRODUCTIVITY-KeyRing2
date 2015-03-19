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
* "Problem reading dongle"
*
* Define DECRYPTON to activate the decrypter
*
* Created by CryptCon on 09-28-1994 11:11:29 am
*
* CryptCon created by Kevin G. McCoy
*
* ~notesend~
* ~nokeywords~
*
***************************************************************************
}
{$A+,B-,D+,E+,F-,G-,I-,L+,N-,O+,P-,Q-,R-,S-,T-,V-,X+,Y+}

UNIT SECON10;

INTERFACE

    {Problem reading dongle}

CONST
    SECON10N       = 36935;
    SECON10P       = 96;
    SECON10S       : ARRAY[0..22] OF BYTE =
    (
        ORD('P') XOR 100,
        ORD('r') XOR 181,
        ORD('o') XOR 60,
        ORD('b') XOR 88,
        ORD('l') XOR 26,
        ORD('e') XOR 153,
        ORD('m') XOR 62,
        ORD(' ') XOR 189,
        ORD('r') XOR 98,
        ORD('e') XOR 40,
        ORD('a') XOR 26,
        ORD('d') XOR 14,
        ORD('i') XOR 236,
        ORD('n') XOR 171,
        ORD('g') XOR 109,
        ORD(' ') XOR 43,
        ORD('d') XOR 193,
        ORD('o') XOR 156,
        ORD('n') XOR 20,
        ORD('g') XOR 101,
        ORD('l') XOR 230,
        ORD('e') XOR 117,
        ORD(0) XOR 176
        );


IMPLEMENTATION
END.
