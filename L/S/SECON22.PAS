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
* "Invalid BIOS address"
*
* Define DECRYPTON to activate the decrypter
*
* Created by CryptCon on 09-30-1994 02:08:01 pm
*
* CryptCon created by Kevin G. McCoy
*
* ~notesend~
* ~nokeywords~
*
***************************************************************************
}

{$O-}
UNIT SECON22;

INTERFACE

{$IFDEF DECRYPTON}
USES
    OpRoot,
    Strings;

FUNCTION DecryptConst(CRP : PCHAR; PubKey, PrivKey : WORD) : STRING;
{$ENDIF}

{Invalid BIOS address}

CONST
    SECON22N = 64108;
    SECON22P = 174;
    SECON22S : ARRAY[0..20] OF BYTE =
    (
        ORD('I') XOR 29,
        ORD('n') XOR 197,
        ORD('v') XOR 124,
        ORD('a') XOR 61,
        ORD('l') XOR 239,
        ORD('i') XOR 70,
        ORD('d') XOR 164,
        ORD(' ') XOR 149,
        ORD('B') XOR 172,
        ORD('I') XOR 88,
        ORD('O') XOR 36,
        ORD('S') XOR 193,
        ORD(' ') XOR 47,
        ORD('a') XOR 139,
        ORD('d') XOR 71,
        ORD('d') XOR 69,
        ORD('r') XOR 206,
        ORD('e') XOR 123,
        ORD('s') XOR 154,
        ORD('s') XOR 151,
        ORD(0) XOR 237
    );


IMPLEMENTATION


{$IFDEF DECRYPTON}
    {Decrypts a string constant array, returning the string on the stack   }
    {CRP is a pointer to the Crypted array; PubKey is the N seed value,    }
    {and PrivKey is the secondary XOR value (see above) for more details   }
    {Calling syntax:  Strg := DecryptConst(@CRYPT1S, CRYPT1N, CRYPT1P);    }
    {   It is probably a good idea to store the PrivKey in a dongle or     }
    {   calculate it just prior to use.                                    }

    FUNCTION DecryptConst(CRP : PCHAR; PubKey, PrivKey : WORD) : STRING;
    VAR
        I              : BYTE;
        T              : PCHAR;
    BEGIN
        DecryptConst := '';

        GetMemCheck(T, $FF);  {get enough memory for a max length string}
        IF T = NIL THEN       {bail on no mem avail }
            EXIT;

        FILLCHAR(T^, $FF, 0);
        {reset the counter}
        I := 0;

        RandSeed := PubKey;

        REPEAT
            {begin decrypting the array}
            T[I] := CHAR(ORD(CRP[I]) XOR RANDOM($FF) XOR PrivKey);
            {inc the counter}
            INC(I);
        UNTIL T[I - 1] = #0;      {quit when null termchar is reached}
        {translate ASCIIZ to pascal string}
        DecryptConst := StrPas(T);

        {clear and deallocate the heap buffer}
        FILLCHAR(T^, $FF, #0);
        FreeMemCheck(T, $FF);
        T := NIL;
    END;

    {--------------}

{$ENDIF}

END.
