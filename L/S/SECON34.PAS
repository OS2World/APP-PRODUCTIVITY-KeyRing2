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
* "Reply     :"
*
* Define DECRYPTON to activate the decrypter
*
* Created by CryptCon v~version~ on 11-01-1994 04:16:47 pm
*
* CryptCon created by Kevin G. McCoy
*
* ~notesend~
* ~nokeywords~
*
***************************************************************************
}

{$A+,B-,D+,E+,F-,G-,I-,L+,N-,O+,P-,Q-,R-,S-,T-,V-,X+,Y+}
UNIT SECON34;

INTERFACE

{Reply     :}

CONST
    SECON34N = 28781;
    SECON34P = 71;
    SECON34S : ARRAY[0..11] OF BYTE =
    (
        ORD('R') XOR 98,
        ORD('e') XOR 240,
        ORD('p') XOR 198,
        ORD('l') XOR 237,
        ORD('y') XOR 114,
        ORD(' ') XOR 77,
        ORD(' ') XOR 245,
        ORD(' ') XOR 173,
        ORD(' ') XOR 12,
        ORD(' ') XOR 56,
        ORD(':') XOR 251,
        ORD(0) XOR 60
    );


IMPLEMENTATION
END.
