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
*
*
* ~notesend~
* ~nokeywords~
*
****************************************************************************

}
{$A-,V-,O-,F+}                    { Do NOT overlay }
{.$D+}

{ Support routines for Ucard that cannot be overlaid }

UNIT UCardLib;

INTERFACE

USES
    Dos, OpCrt, UBtree, UGLOBAL, ULib, UMSg,
    OpField, OpFEdit, OpEntry, OpEditor, OpString,
    OpMouse, OpCmd, OpMenu, OpPick, OpEdit;

FUNCTION LetterItem(Item : WORD) : STRING;
FUNCTION AreaCodeName(Item : WORD) : STRING;
FUNCTION StateName(Item : WORD) : STRING;
PROCEDURE DisplayFieldPrompt;
FUNCTION GetIndex(VAR FR         : EntryFieldPtr;
                  VAR ErrCode    : WORD;
                  VAR ErrorSt    : StringPtr) : BOOLEAN;
FUNCTION ValidateState(VAR FR         : EntryFieldPtr;
                       VAR ErrCode    : WORD;
                       VAR ErrorSt    : StringPtr) : BOOLEAN;
FUNCTION CardItem(Item : WORD) : STRING; { Supplier for PickWindow }
FUNCTION CardFileItem(Item : WORD) : STRING;
FUNCTION LastName(Name : STRING) : STRING;
PROCEDURE DisplayFullState;

TYPE
    MemoBuffer     = ARRAY[1..2048] OF CHAR;

    CardRecord     = RECORD
                         Del            : LONGINT; { 4-byte Delete/Rebuild area for Filer }
                         Index          : STRING[20];
                         Name           : STRING[30];
                         Company        : STRING[30];
                         Phone          : STRING[14];
                         AltPhone       : STRING[20];
                         Remote         : BOOLEAN;
                         Title          : STRING[30];
                         Address        : STRING[30];
                         City           : STRING[20];
                         State          : STRING[2];
                         FullState      : STRING[19];
                         Zip            : STRING[10];
                         Memo           : MemoBuffer; { Text buffer }
                     END;

    AutoDialRecord = RECORD
                         ComPort        : INTEGER; { Com port modem is attached to }
                         Baud           : INTEGER; { Baud rate (Default 1200) }
                         Parity         : CHAR; { Parity E,O,N (Default N) }
                         DataBits       : BYTE; { Data bits (Default 8) }
                         StopBits       : BYTE; { Stop bits (Default 1) }
                         ToneDial       : BOOLEAN; { Tone or Pulse dial (Default Tone) }
                         Access         : WORD; { Access code for outside line (Default 0=none) }
                         LocalArea      : STRING[3]; { Local area code }
                         Emulation      : WORD; { terminal emulation type }
                     END;

    AreaCodeArray  = ARRAY[1..500] OF STRING[30]; { Dummy, actual len will vary }

VAR
    ESR            : EntryScreenPtr;
    EMCB           : TextEditorPtr; { EditMemo control block }
    CardRec        : ^CardRecord;
    CardIndex      : ^DBtree;
    CardFileName   : PathStr;
    CardIsReadOnly : BOOLEAN;

    AutoDial       : AutoDialRecord;

    AreaCodes      : ^AreaCodeArray;
    AreaCodeSize   : WORD;
    TotalAreaCodes : WORD;

    Back, Frame    : BYTE;
    JobDone        : BOOLEAN;
    W_Attr         : BYTE;
    F_Attr         : BYTE;
    H_Attr         : BYTE;
    StateX         : BYTE;
    StateY         : BYTE;
    MainMenu       : Menu;
    Ch             : CHAR;
    KeyRecord      : KeyString;
    AddMode        : BOOLEAN;
    Y, M, D        : WORD;

CONST
(*  StateStrings : array[1..51] of string[19] = (
    {01} 'AK Alaska',
    {02} 'AL Alabama',
    {03} 'AR Arkansas',
    {04} 'AZ Arizona',
    {05} 'CA California',
    {06} 'CO Colorado',
    {07} 'CT Connecticut',
    {08} 'DC Dist of Columbia',
    {09} 'DE Delaware',
    {10} 'FL Florida',
    {11} 'GA Georgia',
    {12} 'HI Hawaii',
    {13} 'IA Iowa',
    {14} 'ID Idaho',
    {15} 'IL Illinois',
    {16} 'IN Indiana',
    {17} 'KS Kansas',
    {18} 'KY Kentucky',
    {19} 'LA Louisana',
    {20} 'MA Massachusetts',
    {21} 'MD Maryland',
    {22} 'ME Maine',
    {23} 'MI Michigan',
    {24} 'MN Minnesota',
    {25} 'MO Missouri',
    {26} 'MS Mississippi',
    {27} 'MT Montana',
    {28} 'NC North Carolina',
    {29} 'ND North Dakota',
    {30} 'NE Nebraska',
    {31} 'NH New Hampshire',
    {32} 'NJ New Jersey',
    {33} 'NM New Mexico',
    {34} 'NV Nevada',
    {35} 'NY New York',
    {36} 'OH Ohio',
    {37} 'OK Oklahoma',
    {38} 'OR Oregon',
    {39} 'PA Pennsylvania',
    {40} 'RI Rhode Island',
    {41} 'SC South Carolina',
    {42} 'SD South Dakota',
    {43} 'TN Tennessee',
    {44} 'TX Texas',
    {45} 'UT Utah',
    {46} 'VA Virginia',
    {47} 'VT Vermont',
    {48} 'WA Washington',
    {49} 'WI Wisconsin',
    {50} 'WV West Virginia',
    {51} 'WY Wyoming');
  *)
    F1Help         : STRING[7] = 'F1-Help';
    F4Dial         : STRING[7] = 'F4-Dial';
    F5Delete       : STRING[9] = 'F5-Delete';
    F7Update       : STRING[9] = 'F7-Update';

    M_Search       = 1;           { Menu ID numbers }
    M_All          = 2;
    M_Letter       = 3;
    M_Name         = 4;

    M_File         = 10;
    M_Create       = 11;
    M_Close        = 12;
    M_Open         = 13;
    M_Delete       = 14;
    M_Add          = 15;
    M_Modem        = 16;

    M_Exit         = 20;

    M_Schedule     = 30;

    M_Comm         = 40;

    M_Edit         = 50;
    M_RRate        = 51;
    M_Pfill        = 52;
    M_Dos          = 53;
    M_WPri         = 54;
    M_Wdf          = 55;

    M_TapeLib      = 70;

    M_Mail         = 80;

    M_Notes        = 90;

    M_Time         = 60;

IMPLEMENTATION

    {-------------------------------------------------------------}
    { Data return function for PickWindow in SelectLetter}

    FUNCTION LetterItem(Item : WORD) : STRING;
    BEGIN
        LetterItem := ' ' + CHR(Item + 64) + ' ';
    END;

    {-------------------------------------------------------------}
    { Area code supplier for PickWindow }

    FUNCTION AreaCodeName(Item : WORD) : STRING;
    BEGIN
        IF Item > 0 THEN
            AreaCodeName := UGLOBAL.Menu^[Item];
    END;

    {-------------------------------------------------------------}
    { State name supplier for PickWindow }

    FUNCTION StateName(Item : WORD) : STRING;
    BEGIN
{  if Item > 0 then
    StateName := StateStrings[Item];}
    END;

    {-------------------------------------------------------------}
    { Help line routine for each field                            }

    PROCEDURE DisplayFieldPrompt;
    VAR 
        S          : STRING[40];
    BEGIN
        S := '';
        CASE ESR^.GetCurrentID OF
            0 : S := SysMsg(001097) {'Last, First or First Last'} ;
            1 : S := SysMsg(001098) {'Company Name'} ;
            2 : S := SysMsg(001099) {'Job Title'} ;
            3 : S := SysMsg(001100) {'Street, Apt/Suite number'} ;
            4 : S := SysMsg(001101) {'City'} ;
            5 : S := SysMsg(001102) {'2-digit State - F1 for list'} ;
            6 : S := SysMsg(001103) {'Zip code'} ;
            7 : S := SysMsg(001104) {'F4 to Dial,F1 for Area codes'} ;
            8 : S := SysMsg(001105) {'Y if Remote computer,N if voice'} ;
            9 : S := SysMsg(001106) {'ENTER to edit notes/Service'} ;
            10 : S := '';
        END;
        WITH ESR^ DO BEGIN
            wFastWrite('                                  ', 1, 2, Attr(White, Red));
            wFastWrite(Pad(S, 31), 1, 2, Attr(White, Red));
        END;
    END;

    {-------------------------------------------------------------}
    { Field validation routine for Name field }

    FUNCTION GetIndex(VAR FR         : EntryFieldPtr;
                      VAR ErrCode    : WORD;
                      VAR ErrorSt    : StringPtr) : BOOLEAN;
    VAR
        Error      : STRING[12] {'Invalid Name'} ;
    BEGIN
        Error := SysMsg(001107);
        CardRec^.Index := LastName(FR^.efEditSt^);
        IF CardRec^.Index = '' THEN BEGIN
            ErrCode := 1;
            ErrorSt := @Error;
            GetIndex := FALSE;
            EXIT;
        END;
        GoToXY(22, 10);
        WRITE(CardRec^.Index);
        GetIndex := TRUE;
    END;

    {-------------------------------------------------------------}
    { Display full state name associated with abbreviation        }

    PROCEDURE DisplayFullState;
    BEGIN
        WITH ESR^ DO BEGIN
            wFastWrite('                    ', StateY, StateX, Attr(White, DarkGray));
            wFastWrite(CardRec^.FullState, StateY, StateX, Attr(White, DarkGray));
        END;
    END;

    {-------------------------------------------------------------}
    { Data validation routine for State field }

    FUNCTION ValidateState(VAR FR         : EntryFieldPtr;
                           VAR ErrCode    : WORD;
                           VAR ErrorSt    : StringPtr) : BOOLEAN;
    VAR
        I          : WORD;
        S              : STRING[2];
        BadState       : STRING[30];
    BEGIN
        S := FR^.efEditSt^;
        BadState := SysMsg(1108);
        IF (S = '  ') {or (S = CardRec^.State)} THEN BEGIN
            ErrCode := 0;
            ValidateState := TRUE;
            EXIT;
        END;
(*  for I := 1 to 51 DO BEGIN
    if (S[1] = StateStrings[I][1]) and (S[2] = StateStrings[I][2]) THEN BEGIN
      CardRec^.FullState := StateStrings[I];
      Delete(CardRec^.FullState,1,3);
{      if ActivateWindow(WP1) then;}
      DisplayFullState;
      ErrCode := 0;
      ValidateState := True;
      exit;
      end;
    end; *)
        ErrCode := 10;
        ErrorSt := @BadState;
        ValidateState := FALSE;
    END;

    {-------------------------------------------------------------}

    FUNCTION CardItem(Item : WORD) : STRING; { Supplier for PickWindow }
    BEGIN
        CardItem := UGLOBAL.Menu^[Item];
    END;

    {-------------------------------------------------------------}
    { Data Supplier for PickWindow                                }

    FUNCTION CardFileItem(Item : WORD) : STRING;
    BEGIN
        CardFileItem := UGLOBAL.Menu^[Item];
    END;

    {-------------------------------------------------------------}
{ Attempts to extract the Last name from a name string for indexing
  Last name is: First word, if terminated by a comma, or more than 1 uppercase
             or Last word that does not contain periods or numerics
  Assumes hyphen is allowed in last name.                     }

    FUNCTION LastName(Name : STRING) : STRING;
    VAR 
        WordS,
        I, 
        J, 
        K        : WORD;
        Delims         : SET OF CHAR;
        ThisOne        : BOOLEAN;
        TestWord       : STRING[20]; { make rash assumption word will be 20 or less }
    CONST Suffixes = 8;
        Suffix         : ARRAY[1..Suffixes] OF STRING[3] =
        ('I', 'II', 'III', 'IV', 'V', 'DDS', 'MD', 'PHD');
    BEGIN
        Delims := [' '];
        WordS := WordCount(Name, Delims);
        IF WordS = 0 THEN BEGIN
            LastName := '';       { No words found }
            EXIT;
        END;

        { Check first word }
        TestWord := ExtractWord(1, Name, Delims);
        IF TestWord[LENGTH(TestWord)] = ',' THEN BEGIN
            DEC(TestWord[0]);
            LastName := StUpCase(TestWord); { comma at end, Last name was first }
            EXIT;
        END;
        J := 0;
        FOR I := 1 TO LENGTH(TestWord) DO { Test for multiple uppers in 1st word }
            IF (CHAR(TestWord[I]) IN['A'..'Z']) THEN
                INC(J);
        IF J > 1 THEN BEGIN
            LastName := StUpCase(TestWord); { more than 1 upper, Last name was first }
            EXIT;
        END;

        { First word didn't qualify, check each word from end until qualifier found }
        Delims := [' ', ','];
        FOR I := WordS DOWNTO 1 DO BEGIN
            ThisOne := TRUE;
            TestWord := ExtractWord(I, Name, Delims);
            FOR J := 1 TO LENGTH(TestWord) DO
                IF NOT(CHAR(TestWord[J]) IN['A'..'Z', 'a'..'z', '-']) THEN
                    ThisOne := FALSE;
            IF ThisOne THEN
                FOR K := 1 TO Suffixes DO
                    IF Suffix[K] = TestWord THEN
                        ThisOne := FALSE;
            IF ThisOne THEN BEGIN
                LastName := StUpCase(TestWord); { Last name last }
                EXIT;
            END;

            LastName := '';       { No qualifying name found }
        END;
    END;

END.

