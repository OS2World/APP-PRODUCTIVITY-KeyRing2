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
* "Windows task ID not found in handle table"
*
* Define DECRYPTON to activate the decrypter
*
* Created by CryptCon on 09-30-1994 02:08:49 pm
*
* CryptCon created by Kevin G. McCoy
*
* ~notesend~
* ~nokeywords~
*
***************************************************************************
}

{$O-}
UNIT SECON26;

INTERFACE

{$IFDEF DECRYPTON}
USES
    OpRoot,
    Strings;

FUNCTION DecryptConst(CRP : PCHAR; PubKey, PrivKey : WORD) : STRING;
{$ENDIF}

{Windows task ID not found in handle table}

CONST
    SECON26N = 20220;
    SECON26P = 90;
    SECON26S : ARRAY[0..41] OF BYTE =
    (
        ORD('W') XOR 218,
        ORD('i') XOR 182,
        ORD('n') XOR 255,
        ORD('d') XOR 33,
        ORD('o') XOR 253,
        ORD('w') XOR 154,
        ORD('s') XOR 187,
        ORD(' ') XOR 10,
        ORD('t') XOR 143,
        ORD('a') XOR 207,
        ORD('s') XOR 123,
        ORD('k') XOR 86,
        ORD(' ') XOR 102,
        ORD('I') XOR 56,
        ORD('D') XOR 185,
        ORD(' ') XOR 15,
        ORD('n') XOR 38,
        ORD('o') XOR 95,
        ORD('t') XOR 233,
        ORD(' ') XOR 242,
        ORD('f') XOR 141,
        ORD('o') XOR 11,
        ORD('u') XOR 57,
        ORD('n') XOR 10,
        ORD('d') XOR 18,
        ORD(' ') XOR 141,
        ORD('i') XOR 135,
        ORD('n') XOR 76,
        ORD(' ') XOR 197,
        ORD('h') XOR 199,
        ORD('a') XOR 244,
        ORD('n') XOR 244,
        ORD('d') XOR 189,
        ORD('l') XOR 30,
        ORD('e') XOR 237,
        ORD(' ') XOR 132,
        ORD('t') XOR 249,
        ORD('a') XOR 0,
        ORD('b') XOR 235,
        ORD('l') XOR 159,
        ORD('e') XOR 249,
        ORD(0) XOR 139
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
