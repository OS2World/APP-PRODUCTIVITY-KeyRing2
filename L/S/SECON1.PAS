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
* "E/"
*
* Define DECRYPTON to activate the decrypter
*
* Created by CryptCon on 09-28-1994 10:53:06 am
*
* CryptCon created by Kevin G. McCoy
*
* ~notesend~
* ~nokeywords~
*
***************************************************************************
}
{$A+,B-,D+,E+,F-,G-,I-,L+,N-,O+,P-,Q-,R-,S-,T-,V-,X+,Y+}

UNIT SECON1;

INTERFACE


    {E/}

CONST
    SECON1N        = 12370;
    SECON1P        = 114;
    SECON1S        : ARRAY[0..2] OF BYTE =
    (
        ORD('E') XOR 89,
        ORD('/') XOR 117,
        ORD(0) XOR 239
        );


IMPLEMENTATION
END.
