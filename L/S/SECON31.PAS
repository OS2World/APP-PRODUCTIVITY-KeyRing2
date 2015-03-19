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
* "Demo Mode - Feature set reduced"
*
* Define DECRYPTON to activate the decrypter
*
* Created by CryptCon v~version~ on 10-14-1994 10:03:50 am
*
* CryptCon created by Kevin G. McCoy
*
* ~notesend~
* ~nokeywords~
*
***************************************************************************
}

{$O-}
UNIT SECON31;

INTERFACE

{$IFDEF DECRYPTON}
USES
    OpRoot,
    Strings;

FUNCTION DecryptConst(CRP : PCHAR; PubKey, PrivKey : WORD) : STRING;
{$ENDIF}

{Demo Mode - Feature set reduced}

CONST
    SECON31N = 34525;
    SECON31P = 123;
    SECON31S : ARRAY[0..31] OF BYTE =
    (
        ORD('D') XOR 31,
        ORD('e') XOR 45,
        ORD('m') XOR 63,
        ORD('o') XOR 201,
        ORD(' ') XOR 243,
        ORD('M') XOR 230,
        ORD('o') XOR 6,
        ORD('d') XOR 200,
        ORD('e') XOR 65,
        ORD(' ') XOR 250,
        ORD('-') XOR 164,
        ORD(' ') XOR 230,
        ORD('F') XOR 82,
        ORD('e') XOR 42,
        ORD('a') XOR 95,
        ORD('t') XOR 0,
        ORD('u') XOR 218,
        ORD('r') XOR 200,
        ORD('e') XOR 98,
        ORD(' ') XOR 151,
        ORD('s') XOR 3,
        ORD('e') XOR 73,
        ORD('t') XOR 93,
        ORD(' ') XOR 87,
        ORD('r') XOR 37,
        ORD('e') XOR 170,
        ORD('d') XOR 169,
        ORD('u') XOR 122,
        ORD('c') XOR 173,
        ORD('e') XOR 184,
        ORD('d') XOR 96,
        ORD(0) XOR 136
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
