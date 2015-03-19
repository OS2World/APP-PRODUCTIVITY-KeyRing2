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
* "SN: "
*
* Define DECRYPTON to activate the decrypter
*
* Created by CryptCon on 09-28-1994 11:12:03 am
*
* CryptCon created by Kevin G. McCoy
*
* ~notesend~
* ~nokeywords~
*
***************************************************************************
}
{$A+,B-,D+,E+,F-,G-,I-,L+,N-,O+,P-,Q-,R-,S-,T-,V-,X+,Y+}

UNIT SECON13;

INTERFACE
    {SN: }

CONST
    SECON13N       = 3691;
    SECON13P       = 148;
    SECON13S       : ARRAY[0..4] OF BYTE =
    (
        ORD('S') XOR 69,
        ORD('N') XOR 194,
        ORD(':') XOR 224,
        ORD(' ') XOR 71,
        ORD(0) XOR 106
        );


IMPLEMENTATION
END.
