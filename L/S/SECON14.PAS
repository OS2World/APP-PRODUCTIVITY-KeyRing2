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
* "Problem writing dongle"
*
* Define DECRYPTON to activate the decrypter
*
* Created by CryptCon on 09-28-1994 11:12:13 am
*
* CryptCon created by Kevin G. McCoy
*
* ~notesend~
* ~nokeywords~
*
***************************************************************************
}

{$O-}
UNIT SECON14;

INTERFACE
    {Problem writing dongle}

CONST
    SECON14N       = 14173;
    SECON14P       = 225;
    SECON14S       : ARRAY[0..22] OF BYTE =
    (
        ORD('P') XOR 95,
        ORD('r') XOR 10,
        ORD('o') XOR 135,
        ORD('b') XOR 195,
        ORD('l') XOR 101,
        ORD('e') XOR 254,
        ORD('m') XOR 64,
        ORD(' ') XOR 37,
        ORD('w') XOR 84,
        ORD('r') XOR 85,
        ORD('i') XOR 24,
        ORD('t') XOR 132,
        ORD('i') XOR 176,
        ORD('n') XOR 0,
        ORD('g') XOR 155,
        ORD(' ') XOR 242,
        ORD('d') XOR 114,
        ORD('o') XOR 187,
        ORD('n') XOR 194,
        ORD('g') XOR 41,
        ORD('l') XOR 26,
        ORD('e') XOR 129,
        ORD(0) XOR 36
        );


IMPLEMENTATION
END.
