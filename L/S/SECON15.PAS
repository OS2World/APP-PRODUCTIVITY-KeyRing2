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
* "Checking for viruses.  Please Wait..."
*
* Define DECRYPTON to activate the decrypter
*
* Created by CryptCon on 09-29-1994 02:01:25 pm
*
* CryptCon created by Kevin G. McCoy
*
* ~notesend~
* ~nokeywords~
*
***************************************************************************
}

{$O-}
UNIT SECON15;

INTERFACE

    {Checking for viruses.  Please Wait...}

CONST
    SECON15N       = 27651;
    SECON15P       = 7;
    SECON15S       : ARRAY[0..37] OF BYTE =
    (
        ORD('C') XOR 168,
        ORD('h') XOR 54,
        ORD('e') XOR 149,
        ORD('c') XOR 41,
        ORD('k') XOR 163,
        ORD('i') XOR 229,
        ORD('n') XOR 250,
        ORD('g') XOR 25,
        ORD(' ') XOR 238,
        ORD('f') XOR 210,
        ORD('o') XOR 227,
        ORD('r') XOR 70,
        ORD(' ') XOR 62,
        ORD('v') XOR 201,
        ORD('i') XOR 151,
        ORD('r') XOR 55,
        ORD('u') XOR 8,
        ORD('s') XOR 163,
        ORD('e') XOR 252,
        ORD('s') XOR 67,
        ORD('.') XOR 115,
        ORD(' ') XOR 154,
        ORD(' ') XOR 178,
        ORD('P') XOR 37,
        ORD('l') XOR 75,
        ORD('e') XOR 93,
        ORD('a') XOR 199,
        ORD('s') XOR 202,
        ORD('e') XOR 122,
        ORD(' ') XOR 32,
        ORD('W') XOR 66,
        ORD('a') XOR 66,
        ORD('i') XOR 156,
        ORD('t') XOR 177,
        ORD('.') XOR 113,
        ORD('.') XOR 194,
        ORD('.') XOR 237,
        ORD(0) XOR 144
        );


IMPLEMENTATION
END.
