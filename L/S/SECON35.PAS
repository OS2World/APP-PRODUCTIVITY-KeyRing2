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
* "Refresh Key"
*
* Define DECRYPTON to activate the decrypter
*
* Created by CryptCon v~version~ on 11-01-1994 04:16:53 pm
*
* CryptCon created by Kevin G. McCoy
*
* ~notesend~
* ~nokeywords~
*
***************************************************************************
}

{$A+,B-,D+,E+,F-,G-,I-,L+,N-,O+,P-,Q-,R-,S-,T-,V-,X+,Y+}
UNIT SECON35;

INTERFACE

{Refresh Key}

CONST
    SECON35N = 8687;
    SECON35P = 164;
    SECON35S : ARRAY[0..11] OF BYTE =
    (
        ORD('R') XOR 60,
        ORD('e') XOR 248,
        ORD('f') XOR 100,
        ORD('r') XOR 155,
        ORD('e') XOR 181,
        ORD('s') XOR 222,
        ORD('h') XOR 249,
        ORD(' ') XOR 227,
        ORD('K') XOR 52,
        ORD('e') XOR 173,
        ORD('y') XOR 137,
        ORD(0) XOR 92
    );


IMPLEMENTATION
END.
