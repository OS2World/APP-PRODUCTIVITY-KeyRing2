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
* "KKKKKKKK"
*
* Define DECRYPTON to activate the decrypter
*
* Created by CryptCon v~version~ on 11-01-1994 04:17:03 pm
*
* CryptCon created by Kevin G. McCoy
*
* ~notesend~
* ~nokeywords~
*
***************************************************************************
}
{$A+,B-,D+,E+,F-,G-,I-,L+,N-,O+,P-,Q-,R-,S-,T-,V-,X+,Y+}

UNIT SECON36;

INTERFACE

{KKKKKKKK}

CONST
    SECON36N = 10669;
    SECON36P = 137;
    SECON36S : ARRAY[0..8] OF BYTE =
    (
        ORD('K') XOR 67,
        ORD('K') XOR 74,
        ORD('K') XOR 34,
        ORD('K') XOR 32,
        ORD('K') XOR 210,
        ORD('K') XOR 110,
        ORD('K') XOR 236,
        ORD('K') XOR 233,
        ORD(0) XOR 240
    );


IMPLEMENTATION
END.
