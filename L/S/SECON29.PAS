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
* "cIMa GAlINa"
*
* Define DECRYPTON to activate the decrypter
*
* Created by CryptCon v~version~ on 10-13-1994 05:41:57 pm
*
* CryptCon created by Kevin G. McCoy
*
* ~notesend~
* ~nokeywords~
*
***************************************************************************
}

{$O-}
UNIT SECON29;

INTERFACE

{$IFDEF DECRYPTON}
USES
    OpRoot,
    Strings;

FUNCTION DecryptConst(CRP : PCHAR; PubKey, PrivKey : WORD) : STRING;
{$ENDIF}

{cIMa GAlINa}

CONST
    SECON29N = 26648;
    SECON29P = 206;
    SECON29S : ARRAY[0..11] OF BYTE =
    (
        ORD('c') XOR 248,
        ORD('I') XOR 199,
        ORD('M') XOR 202,
        ORD('a') XOR 110,
        ORD(' ') XOR 120,
        ORD('G') XOR 41,
        ORD('A') XOR 149,
        ORD('l') XOR 197,
        ORD('I') XOR 159,
        ORD('N') XOR 73,
        ORD('a') XOR 32,
        ORD(0) XOR 126
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
