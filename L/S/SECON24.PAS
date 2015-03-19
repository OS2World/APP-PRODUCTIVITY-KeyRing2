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
* "busy or missing"
*
* Define DECRYPTON to activate the decrypter
*
* Created by CryptCon on 09-30-1994 02:08:11 pm
*
* CryptCon created by Kevin G. McCoy
*
* ~notesend~
* ~nokeywords~
*
***************************************************************************
}

{$O-}
UNIT SECON24;

INTERFACE

{$IFDEF DECRYPTON}
USES
    OpRoot,
    Strings;

FUNCTION DecryptConst(CRP : PCHAR; PubKey, PrivKey : WORD) : STRING;
{$ENDIF}

{busy or missing}

CONST
    SECON24N = 13652;
    SECON24P = 121;
    SECON24S : ARRAY[0..15] OF BYTE =
    (
        ORD('b') XOR 28,
        ORD('u') XOR 208,
        ORD('s') XOR 12,
        ORD('y') XOR 5,
        ORD(' ') XOR 191,
        ORD('o') XOR 125,
        ORD('r') XOR 25,
        ORD(' ') XOR 89,
        ORD('m') XOR 167,
        ORD('i') XOR 184,
        ORD('s') XOR 47,
        ORD('s') XOR 135,
        ORD('i') XOR 121,
        ORD('n') XOR 160,
        ORD('g') XOR 176,
        ORD(0) XOR 128
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
