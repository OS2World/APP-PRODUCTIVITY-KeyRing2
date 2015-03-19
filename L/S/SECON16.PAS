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
* "Virus Check Complete."
*
* Define DECRYPTON to activate the decrypter
*
* Created by CryptCon on 09-29-1994 02:03:08 pm
*
* CryptCon created by Kevin G. McCoy
*
* ~notesend~
* ~nokeywords~
*
***************************************************************************
}

{$O-}
UNIT SECON16;

INTERFACE

    {Virus Check Complete.}

CONST
    SECON16N       = 4219;
    SECON16P       = 41;
    SECON16S       : ARRAY[0..21] OF BYTE =
    (
        ORD('V') XOR 74,
        ORD('i') XOR 79,
        ORD('r') XOR 225,
        ORD('u') XOR 223,
        ORD('s') XOR 175,
        ORD(' ') XOR 173,
        ORD('C') XOR 118,
        ORD('h') XOR 44,
        ORD('e') XOR 249,
        ORD('c') XOR 170,
        ORD('k') XOR 19,
        ORD(' ') XOR 37,
        ORD('C') XOR 207,
        ORD('o') XOR 105,
        ORD('m') XOR 86,
        ORD('p') XOR 204,
        ORD('l') XOR 62,
        ORD('e') XOR 83,
        ORD('t') XOR 211,
        ORD('e') XOR 101,
        ORD('.') XOR 235,
        ORD(0) XOR 93
        );


IMPLEMENTATION
END.
