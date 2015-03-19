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
* "OS/2 parallel port access failure"
*
* Define DECRYPTON to activate the decrypter
*
* Created by CryptCon on 09-30-1994 02:08:36 pm
*
* CryptCon created by Kevin G. McCoy
*
* ~notesend~
* ~nokeywords~
*
***************************************************************************
}

{$O-}
UNIT SECON25;

INTERFACE

{$IFDEF DECRYPTON}
USES
    OpRoot,
    Strings;

FUNCTION DecryptConst(CRP : PCHAR; PubKey, PrivKey : WORD) : STRING;
{$ENDIF}

{OS/2 parallel port access failure}

CONST
    SECON25N = 28431;
    SECON25P = 205;
    SECON25S : ARRAY[0..33] OF BYTE =
    (
        ORD('O') XOR 228,
        ORD('S') XOR 155,
        ORD('/') XOR 58,
        ORD('2') XOR 193,
        ORD(' ') XOR 106,
        ORD('p') XOR 95,
        ORD('a') XOR 81,
        ORD('r') XOR 142,
        ORD('a') XOR 90,
        ORD('l') XOR 10,
        ORD('l') XOR 142,
        ORD('e') XOR 56,
        ORD('l') XOR 198,
        ORD(' ') XOR 75,
        ORD('p') XOR 13,
        ORD('o') XOR 40,
        ORD('r') XOR 71,
        ORD('t') XOR 36,
        ORD(' ') XOR 75,
        ORD('a') XOR 102,
        ORD('c') XOR 117,
        ORD('c') XOR 253,
        ORD('e') XOR 17,
        ORD('s') XOR 1,
        ORD('s') XOR 184,
        ORD(' ') XOR 26,
        ORD('f') XOR 104,
        ORD('a') XOR 189,
        ORD('i') XOR 214,
        ORD('l') XOR 132,
        ORD('u') XOR 22,
        ORD('r') XOR 46,
        ORD('e') XOR 123,
        ORD(0) XOR 146
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
