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
* "Invalid request char"
*
* Define DECRYPTON to activate the decrypter
*
* Created by CryptCon on 09-30-1994 02:07:55 pm
*
* CryptCon created by Kevin G. McCoy
*
* ~notesend~
* ~nokeywords~
*
***************************************************************************
}

{$O-}
UNIT SECON21;

INTERFACE

{$IFDEF DECRYPTON}
USES
    OpRoot,
    Strings;

FUNCTION DecryptConst(CRP : PCHAR; PubKey, PrivKey : WORD) : STRING;
{$ENDIF}

{Invalid request char}

CONST
    SECON21N = 34117;
    SECON21P = 2;
    SECON21S : ARRAY[0..20] OF BYTE =
    (
        ORD('I') XOR 148,
        ORD('n') XOR 214,
        ORD('v') XOR 233,
        ORD('a') XOR 2,
        ORD('l') XOR 219,
        ORD('i') XOR 162,
        ORD('d') XOR 130,
        ORD(' ') XOR 212,
        ORD('r') XOR 111,
        ORD('e') XOR 186,
        ORD('q') XOR 156,
        ORD('u') XOR 139,
        ORD('e') XOR 224,
        ORD('s') XOR 7,
        ORD('t') XOR 218,
        ORD(' ') XOR 230,
        ORD('c') XOR 196,
        ORD('h') XOR 191,
        ORD('a') XOR 95,
        ORD('r') XOR 19,
        ORD(0) XOR 176
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
