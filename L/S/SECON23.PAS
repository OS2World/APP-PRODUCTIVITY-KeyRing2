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
* "driver corrupted"
*
* Define DECRYPTON to activate the decrypter
*
* Created by CryptCon on 09-30-1994 02:08:05 pm
*
* CryptCon created by Kevin G. McCoy
*
* ~notesend~
* ~nokeywords~
*
***************************************************************************
}

{$O-}
UNIT SECON23;

INTERFACE

{$IFDEF DECRYPTON}
USES
    OpRoot,
    Strings;

FUNCTION DecryptConst(CRP : PCHAR; PubKey, PrivKey : WORD) : STRING;
{$ENDIF}

{driver corrupted}

CONST
    SECON23N = 28425;
    SECON23P = 45;
    SECON23S : ARRAY[0..16] OF BYTE =
    (
        ORD('d') XOR 213,
        ORD('r') XOR 118,
        ORD('i') XOR 198,
        ORD('v') XOR 178,
        ORD('e') XOR 110,
        ORD('r') XOR 156,
        ORD(' ') XOR 160,
        ORD('c') XOR 45,
        ORD('o') XOR 104,
        ORD('r') XOR 250,
        ORD('r') XOR 202,
        ORD('u') XOR 79,
        ORD('p') XOR 65,
        ORD('t') XOR 27,
        ORD('e') XOR 119,
        ORD('d') XOR 10,
        ORD(0) XOR 251
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
