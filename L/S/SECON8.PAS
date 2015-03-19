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
* "/"
*
* Define DECRYPTON to activate the decrypter
*
* Created by CryptCon on 09-28-1994 11:05:09 am
*
* CryptCon created by Kevin G. McCoy
*
* ~notesend~
* ~nokeywords~
*
***************************************************************************
}
{$A+,B-,D+,E+,F-,G-,I-,L+,N-,O+,P-,Q-,R-,S-,T-,V-,X+,Y+}
UNIT SECON8;

INTERFACE

    {/}

CONST
    SECON8N        = 65106;
    SECON8P        = 10;
    SECON8S        : ARRAY[0..1] OF BYTE =
    (
        ORD('/') XOR 15,
        ORD(0) XOR 103
        );


IMPLEMENTATION
END.
