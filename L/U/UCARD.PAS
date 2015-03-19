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
{$A-,V-,O+,F+,X+}

{---------------------------------------------------------}
{ (C) 1990 NewsMaker Systems.                             }
{ Card index subsystem.                                   }
{---------------------------------------------------------}

UNIT UCard;

INTERFACE

USES
    Dos,
    Printer,
    UMsg,
    OpCrt,
    OpDos,
    OpString,
    OpRoot,
    OpEntry,
    OpDate,
    OpMemo,
    OpEditor,
    OpMouse,
    OpCol16,
    OpField,
    OpFEdit,
    OpFrame,
    OpWindow,
    OpCmd,
    OpDrag,
    OpKey,
    QHdrRec,
    QNovell,
    QInput,
    QScreen,
    QGlobal,
    QDrives,
    UBtree,
    UGlobal,
    UColors,
    UWindow,
    UMenu,
    ULib,
    UKey,
    UCalndr,
    UMatrix,
{    UVscreen,}
    UService,
    UComm,
    UAsynch,
    UMail,
    UWsData,
    UFkey,
    UCardLib,
    UDialog,
    UEdit,
    Filer,
    Browser,
    Reorg,
    Reindex,
    NumKeys,
    NetWare;

PROCEDURE OpenCardIndex;
PROCEDURE CloseCardIndex;
PROCEDURE SearchCardIndex;
PROCEDURE DoSearch;
    {Procedure AddCardToFile(CardContents: CardIndexPtr);}

CONST
    SecurityClearance : BYTE = 3;
    SecurityRequested : BYTE = 0;
    CardIndexName  : PathStr = 'CARD'; { Default name }

IMPLEMENTATION

{$I UCardGlo}

    {--------------------------------------------------------------------}
    { Computes 6-bit packed size of key, input is unpacked length        }
    FUNCTION KeySize(Len : BYTE) : BYTE;
    BEGIN
        KeySize := (Len * 6) DIV 8 + ORD((Len * 6) MOD 8 <> 0);
    END;

    {--------------------------------------------------------------------}
    PROCEDURE DefineCardIndexKeys;
    VAR 
        I          : INTEGER;
    BEGIN
        WITH CardIndex^ DO BEGIN
            FILLCHAR(IID, SIZEOF(IID), #0);
            DefineKey(1, KeySize(KeyLength[1]), Unique);
            FOR I := 2 TO TotalKeys DO
                DefineKey(I, KeySize(KeyLength[I]), AllowDuplicates);
        END;
    END;

    {--------------------------------------------------------------------}
    PROCEDURE CloseCardIndex;
    BEGIN
        IF CardIndexOpen THEN
            CardIndex^.CLOSE;
        DISPOSE(CardIndex, Done);
        CardIndexOpen := FALSE;
    END;

    {--------------------------------------------------------------------}
    PROCEDURE CreateCardIndex;
    BEGIN
        NEW(CardIndex, Init);
        WITH CardIndex^ DO BEGIN
            DefineCardIndexKeys;
            Create(stUPCASE(CardPath + '\' + CardIndexName), SIZEOF(Card_Index), TotalKeys, FixedRecs);
        END;
        CardIndexOpen := CardIndex^.LastBtStatus = 0;
    END;

    {-------------------------------------------------------------}
    { Create a new Card index file }

    PROCEDURE CreateCardFile;
    VAR 
        DB_Len     : INTEGER;
        FileName       : NameStr;
        Escape         : BOOLEAN;
    BEGIN
        IF CardIndexOpen THEN
            CloseCardIndex;
        FileName := '';
        GetInput(SysMsg(001073) {'File Name'} , 'CIX', GREEN, '', 8, FileName, Escape);
        IF FileName <> '' THEN BEGIN
            CardPath := '';
            CASE Dialog( SysMsg(001110) {'Availability'},
                         SysMsg(000975) {'CREATE'} ,
                         Brown,
                         SysMsg(001111) {'Public'} ,
                         GetUserName) OF
                1 : CardPath := NEN^.PublicDir;
                2 : CardPath := NEN^.PrivateDir + '\' + GetUserName + '\PRIVATE';
            END;
            CardIndexName := stUPCASE(FileName);
            CreateCardIndex;
            CloseCardIndex;
        END;
        OpenCardIndex;
    END;

    {--------------------------------------------------------------------}
    PROCEDURE OpenCardIndex;
    BEGIN
        IF CardIndexOpen THEN EXIT;
        NEW(CardIndex, Init);
        IF DatabaseExists(CardPath + '\' + CardIndexName) THEN
            CardIndex^.Open(CardPath + '\' + CardIndexName, FixedRecs)
        ELSE
            CreateCardFile;
        CardIndexOpen := CardIndex^.LastBtStatus = 0;
    END;

    {--------------------------------------------------------------------}
    PROCEDURE ClearSearchMask;
    BEGIN
        FILLCHAR(SearchMask^, SIZEOF(Card_Search), #0);
        ESRSearch^.SetNextField(0);
    END;

    {--------------------------------------------------------------------}
    PROCEDURE InitEntryScreen;
    BEGIN
        ClearSearchMask;
        Green_Scheme;

        WITH NENColorSet DO BEGIN
            SetPromptAttr(DkGrayOnGreen, $07);
            SetTextAttr(BlackOnGreen, $07);
            SetFieldAttr(BlackOnGreen, $07);
            SetSelectedFieldAttr(BlackOnLtGreen, $07);
        END;

        NEW(ESRSearch, InitCustom(9, 8, 42, 20, NENColorSet,
                                  DefWindowOptions OR wBordered));
        CustomizeWindow(ESRSearch^, ' Search  ', 10);

        CustomizeCommandProcessor(EntryCommands);
        WITH ESRSearch^, EntryCommands DO BEGIN
            AddCommand(ccUser1, 1, $3B00, 0); { F1 }
            AddCommand(ccUser2, 1, $3C00, 0); { F2 }
            AddCommand(ccUser3, 1, $3D00, 0); { F3 }
            AddCommand(ccUser4, 1, $3E00, 0); { F4 }
            AddCommand(ccUser5, 1, $3F00, 0); { F5 }
            AddCommand(ccUser6, 1, $4000, 0); { F6 }
            AddCommand(ccUser7, 1, $4100, 0); { F7 }
            AddCommand(ccUser8, 1, $4200, 0); { F8 }
            AddCommand(ccUser9, 1, $4300, 0); { F9 }
            AddCommand(ccUser0, 1, $4400, 0); { F10 }
        END;

        White_Scheme;

        NEW(ESRCard, InitCustom(32, 6, 75, 18, NENColorSet,
                                DefWindowOptions OR wBordered));

        CustomizeWindow(ESRCard^, ' Card ', 10);

        CustomizeCommandProcessor(EntryCommands);
        WITH ESRCard^, EntryCommands DO BEGIN
            AddCommand(ccUser1, 1, $3B00, 0); { F1 }
            AddCommand(ccUser2, 1, $3C00, 0); { F2 }
            AddCommand(ccUser3, 1, $3D00, 0); { F3 }
            AddCommand(ccUser4, 1, $3E00, 0); { F4 }
            AddCommand(ccUser5, 1, $3F00, 0); { F5 }
            AddCommand(ccUser6, 1, $4000, 0); { F6 }
            AddCommand(ccUser7, 1, $4100, 0); { F7 }
            AddCommand(ccUser8, 1, $4200, 0); { F8 }
            AddCommand(ccUser9, 1, $4300, 0); { F9 }
            AddCommand(ccUser0, 1, $4400, 0); { F10 }
            AddCommand(ccNextRec, 1, OpKey.PgDn, 0);
            AddCommand(ccPrevRec, 1, OpKey.PgUp, 0);
        END;

        WITH ESRCard^ DO BEGIN
            esFieldOptionsOff(efRequired);
            AddStringField(SysMsg(001112) {'Name   : '} , 2, 2, '', 2, 11, 30, 1, CardData^.Name);
            AddStringField(SysMsg(001113) {'Company: '} , 3, 2, '', 3, 11, 30, 2, CardData^.Company);
            AddStringField(SysMsg(001114) {'Title  : '} , 4, 2, '', 4, 11, 30, 3, CardData^.Title);
            AddStringField(SysMsg(001115) {'Street : '} , 5, 2, '', 5, 11, 30, 4, CardData^.Address);
            AddStringField(SysMsg(001116) {'City   : '} , 6, 2, '', 6, 11, 20, 5, CardData^.City);
            AddStringField(SysMsg(001117) {'State  : '} , 7, 2, '', 7, 11, 20, 6, CardData^.State);
            AddStringField(SysMsg(001118) {'Zip    : '} , 8, 2, '', 8, 11, 10, 7, CardData^.Zip);
            AddStringField(SysMsg(001119) {'Country: '} , 9, 2, '', 9, 11, 20, 8, CardData^.Country);
            AddStringField(SysMsg(001120) {'Phone  : ('} , 10, 2, '999', 10, 12, 3, 9, CardData^.Areacode);
            AddStringField(')', 10, 15, '', 10, 16, 10, 10, CardData^.Phone);
            AddStringField(SysMsg(001121) {'Alt Ph : '} , 11, 2, '', 11, 11, 14, 12, CardData^.AltPhone);
            AddNestedField(SysMsg(001122) {'Notes  : '} , 12, 2, '', 12, 11, 1, 13);
            AddStringField(SysMsg(001123) {'Remote : '} , 12, 14, '', 12, 22, 20, 11, CardData^.Remote);
        END;

        WITH ESRSearch^ DO BEGIN
            esFieldOptionsOff(efRequired);
            AddStringField(SysMsg(000783) {'Keyword : '} , 2, 2, '!!!!!!!!!!!!!!!', 2, 12, 15, 3, SearchMask^.Keywords[1]);
            AddStringField(SysMsg(000783) {'Keyword : '} , 3, 2, '!!!!!!!!!!!!!!!', 3, 12, 15, 4, SearchMask^.Keywords[2]);
            AddStringField(SysMsg(000783) {'Keyword : '} , 4, 2, '!!!!!!!!!!!!!!!', 4, 12, 15, 5, SearchMask^.Keywords[3]);
            AddStringField(SysMsg(000783) {'Keyword : '} , 5, 2, '!!!!!!!!!!!!!!!', 5, 12, 15, 6, SearchMask^.Keywords[4]);
            AddStringField(SysMsg(000783) {'Keyword : '} , 6, 2, '!!!!!!!!!!!!!!!', 6, 12, 15, 7, SearchMask^.Keywords[5]);
            AddStringField(SysMsg(001124) {'City    : '} , 7, 2, '', 7, 12, 20, 8, SearchMask^.City);
            AddStringField(SysMsg(001125) {'State   : '} , 8, 2, '', 8, 12, 20, 9, SearchMask^.State);
            AddStringField(SysMsg(001126) {'Country : '} , 9, 2, '', 9, 12, 20, 10, SearchMask^.Country);
            AddStringField(SysMsg(001127) {'Zip     : '} , 10, 2, '', 10, 12, 10, 11, SearchMask^.Zip);
            AddStringField(SysMsg(001128) {'AreaCode: '} , 11, 2, '', 11, 12, 3, 12, SearchMask^.Areacode);
        END;
        F1Help := SysMsg(001093) {'F1-Help'} ;
        F4Dial := SysMsg(001094) {'F4-Dial'} ;
        F5Delete := SysMsg(001095) {'F5-Delete'} ;
        F7Update := SysMsg(001096) {'F7-Update'} ;
    END;

    {-------------------------------------------------------------}
    { Defines Notes window, does not display  }

    PROCEDURE Initmemo;
    BEGIN
        {instantiate a TextEditor with a bordered window}
        NEW(EMCB, OpenEditBufCustom(27, 10, 67, 19, {Window coordinates}
                                    ' Notes ',
                                    TextColors,
                                    @CardData^.Memo, 512));
    END;

    {-------------------------------------------------------------}
    { EditNotes - Called to open & process the notes window       }
    PROCEDURE EditNotes;
    VAR
        Mx, My         : BYTE;
    BEGIN
        Mx := MouseWhereX;
        My := MouseWhereY;

        HideMouse;

        ShowMouse;
        Initmemo;

        {start editing}
        ProcessEdit(EMCB);

        DISPOSE(EMCB, Done);
        ShowMouse;
    END;

    {-------------------------------------------------------------}
    { Select Area Code }

    PROCEDURE SelectAreaCode(VAR Code : STRING);
    VAR 
        Choice     : WORD;
        Codes          : INTEGER;
        I, ST          : INTEGER;
        F              : TEXT;
    BEGIN

        IF AreaCodes = NIL THEN   { Allocate heap, & read data file if first time }
        BEGIN
            ASSIGN(F, {NEN^.SysDir+'\'+} 'AREACODE.DAT');
    {$I-}
            RESET(F);
            IF IORESULT <> 0 THEN BEGIN
                IF Dialog(SysMsg(001130) {'Area code file not found'} , 'CIX', RED, 'Ok', '') = 0 THEN ;
                EXIT;
            END;
            AreaCodeSize := (TextFileSize(F) DIV 30) * SIZEOF(BigString);
            GetMemCheck(AreaCodes, AreaCodeSize);
            IF AreaCodes = NIL THEN BEGIN
                IF Dialog(SysMsg(000859) {'Not enough Memory!'} , 'CIX', RED, 'Ok', '') = 0 THEN ;
                EXIT;
            END;
            I := 0;
            WHILE NOT EOF(F) DO BEGIN
                INC(I);
                READLN(F, AreaCodes^[I]);
            END;
            TotalAreaCodes := I;
            CLOSE(F);
        END;

        Codes := TotalAreaCodes;
        ST := 1;
        IF CardData^.StateCode <> '' THEN BEGIN
            FOR I := 1 TO TotalAreaCodes DO IF CardData^.StateCode = COPY(AreaCodes^[I], 1, 2) THEN BEGIN
                ST := I;
                I := 0;
                REPEAT
                    INC(I);
                UNTIL (COPY(AreaCodes^[ST + I], 1, 2) <> CardData^.StateCode) OR(ST + I > TotalAreaCodes);
                Codes := I;
                I := TotalAreaCodes;
            END;
        END;

        IF Codes = 0 THEN BEGIN
            Code := '';
            EXIT;
        END;

        IF Codes = 1 THEN BEGIN
            Code := ExtractWord(WordCount(AreaCodes^[ST], [' ']), AreaCodes^[ST], [' ']);
            EXIT;
        END;

        OpenMenu(10, 8, 45, 20, AreaCodes^[ST], Codes, 30, Sort, '', SysMsg(001131) {'Area Codes'} , Yellow_Scheme, I);
        Choice := GetMenu;
        CloseWindow;

        IF Choice > 0 THEN BEGIN
            Choice := Choice + (ST - 1);
            Code := ExtractWord(WordCount(AreaCodes^[Choice], [' ']),
                                AreaCodes^[Choice], [' ']);
            CardData^.StateCode := COPY(AreaCodes^[Choice], 1, 2);
{      for I := 1 to 51 do        if CardData^.StateCode = Copy(StateStrings[I],1,2) then          begin
            CardData^.State := Copy(StateStrings[I],4,24);
            exit;
          end;   }
        END
        ELSE
            Code := '';
    END;

    {-------------------------------------------------------------}
    { Select State }

    PROCEDURE SelectState(VAR State : WORD);
    VAR 
        Choice     : WORD;
        I              : INTEGER;
    BEGIN
(*  OpenMenu(10,8,33,20,StateStrings,51,19,Sort,'',SysMsg(001132){'US States'},Red_Scheme,I);
  State := GetMenu;
  CloseWindow;*)
    END;

    {--------------------------------------------------------------------}
    PROCEDURE ProcessHelp(ESR : EntryScreen);
    VAR 
        Yr, Mo, Da : WORD;
        S              : WORD;
    BEGIN
        CASE ESR.GetCurrentID OF
            6 : BEGIN
                    SelectState(S);
                    IF S > 0 THEN BEGIN
{                   CardData^.State := Trim(Copy(StateStrings[S],3,16));
                   CardData^.StateCode := Trim(Copy(StateStrings[S],1,2));}
                    END;
                END;
            9 : BEGIN
                    SelectAreaCode(CardData^.Areacode);
                END;
            11 : BEGIN
                     SelectService(S);
                     IF S <> 0 THEN
                         CardData^.Remote := Menu^[S];
                     SetBorderType(2);
                 END;
            13 : EditNotes;
        END;
    END;

    {--------------------------------------------------------------------}
    PROCEDURE ResetTimer;
    BEGIN
    END;

    {--------------------------------------------------------------------}
    PROCEDURE DrawTimer;
    VAR 
        Atr        : BYTE;
    BEGIN
    END;

    {--------------------------------------------------------------------}
    PROCEDURE StartTimer;
    BEGIN
    END;

    {--------------------------------------------------------------------}
    PROCEDURE StopTimer;
    BEGIN
    END;

    {--------------------------------------------------------------------}
    PROCEDURE ReStartTimer;
    BEGIN
    END;

    {--------------------------------------------------------------------}
    PROCEDURE EraseTimer;
    BEGIN
    END;

    {--------------------------------------------------------------------}
    { Search Card library via any of the indexed keys }
    PROCEDURE SearchCards;
    VAR 
        Done       : BOOLEAN;
    BEGIN
        ClearSearchMask;
        WITH ESRSearch^ DO BEGIN
            Draw;
            wFastWrite(SysMsg(000790) {'Enter Search fields'} , 1, 2, Attr(GREEN, WHITE));
            wFastWrite(Long2Str(CardIndex^.NumRecs - 1) + SysMsg(001133) {' Cards in Library'} ,
                       12, 2, Attr(GREEN, WHITE));
        END;
        Done := FALSE;
        DrawTimer;
        ResetTimer;
        WHILE NOT Done DO BEGIN
            ClearFKeys;
            SetTag(5, UnShift, SysMsg(000793) {'CLEAR'} );
            SetTag(10, UnShift, SysMsg(000794) {'SEARCH'} );
            ESRSearch^.Process;
            CASE ESRSearch^.GetLastCommand OF
                ccMouseDown,
                ccMouseSel :
                    {did user click on the hot spot for closing?}
                    IF HandleMousePress(ESRSearch^) = hsRegion3 THEN BEGIN
                        ClearMouseEvents;
                        Done := TRUE;
                    END;
                ccNone : BEGIN
                             IF Dialog(SysMsg(000795) {'Error!'} , SysMsg(000794) {'SEARCH'} , RED, 'OK', '') = 0 THEN ;
                             Done := TRUE;
                         END;
                ccDone,
                ccQuit : Done := TRUE;
                ccUser2 : WriteWindowTitle(SysMsg(000789) {'Search By'} );
                ccUser1 : ProcessHelp(ESRSearch^);
                ccUser5 : ClearSearchMask;
                ccUser0 : DoSearch;
            END;
        END;
        EraseTimer;
        ESRSearch^.ERASE;
    END;

    {--------------------------------------------------------------------}

    PROCEDURE ReadCard(Lock : BOOLEAN);
    BEGIN
        CASE Lock OF
            TRUE : CardIndex^.GetLocked(SIZEOF(Card_Index), CardData^);
            FALSE : CardIndex^.GetReadOnly(SIZEOF(Card_Index), CardData^);
        END;
    END;

    {--------------------------------------------------------------------}

    FUNCTION Pack(InS : Stype) : Stype;
    VAR 
        I          : INTEGER;
        Out            : Stype;
    BEGIN
        Out := '';
        InS := Trim(InS);
        FOR I := 1 TO LENGTH(InS) DO
            IF UPCASE(InS[I]) IN['A'..'Z', '0'..'9'] THEN
                Out := Out + UPCASE(InS[I]);
        Pack := Out;
    END;

    {--------------------------------------------------------------------}
    PROCEDURE AddKey(Key : INTEGER; KeySt : Stype);
    BEGIN
        IF KeySt = '' THEN EXIT;
        CardIndex^.AddIndex(Key, Pack6BitKeyUC(Trim(KeySt), KeySize(KeyLength[Key])));
    END;

    {--------------------------------------------------------------------}
    PROCEDURE DeleteKey(Key : INTEGER; KeySt : Stype);
    BEGIN
        IF KeySt = '' THEN EXIT;
        CardIndex^.DeleteIndex(Key, Pack6BitKeyUC(Trim(KeySt), KeySize(KeyLength[Key])));
        IF CardIndex^.LastBtStatus <> 0 THEN
            IF Dialog( SysMsg(000726) {'Key: '} +
                       Long2Str(Key) +
                       ' ' +
                       KeySt,
                       SysMsg(000727) {'ERROR'} ,
                       RED,
                       'OK', '') = 0 THEN ;
    END;


    {--------------------------------------------------------------------}
    PROCEDURE ChangeKey(Key : INTEGER; OldKeySt : Stype; KeySt : Stype);
    BEGIN
        DeleteKey(Key, OldKeySt);
        AddKey(Key, KeySt);
    END;

    {--------------------------------------------------------------------}

    PROCEDURE AddAllKeys(CardContents : CardIndexPtr);
    VAR
        I, J, Key, TV  : INTEGER;
        CardID         : STRING[8];
    CONST
        Delims         : SET OF CHAR = [' ', '-', '/', ',', '.'];

        FUNCTION DuplicateKey(VAR KeyWord : KeyWordSt; Num : INTEGER) : BOOLEAN;
        VAR 
            I          : INTEGER;
        BEGIN
            WITH CardContents^ DO BEGIN
                FOR I := 1 TO NumKeywords DO
                    IF I <> Num THEN
                        IF Trim(KeyWord) = Trim(Keywords[I]) THEN BEGIN
                            KeyWord := '';
                            DuplicateKey := TRUE;
                            EXIT;
                        END;
                DuplicateKey := FALSE;
            END;
        END;

        PROCEDURE BuildKeywords(Wd : STRING);
        VAR 
            I          : INTEGER;
        BEGIN
            WITH CardContents^ DO BEGIN
                FOR I := 1 TO WordCount(Wd, Delims) DO BEGIN
                    INC(Key);
                    INC(J);
                    IF Key <= TotalKeys THEN BEGIN
                        Keywords[J] := Pack(ExtractWord(I, Wd, Delims));
                        IF (LENGTH(Keywords[J]) > 1) AND(NOT DuplicateKey(Keywords[J], J)) THEN
                            AddKey(Key, Keywords[J])
                        ELSE
                            DEC(J);
                    END
                END;
            END;
        END;

    BEGIN
        WITH CardContents^ DO BEGIN
            IF CardIndex^.LastBtStatus = 0 THEN BEGIN
                AddKey(2, Pack(City));
                AddKey(3, Pack(State));
                AddKey(4, Pack(Zip));
                AddKey(5, Pack(Country));
                AddKey(6, Pack(Areacode));
                AddKey(7, Pack(Phone));
                J := 0;           { First computed keyword offset is 1 }
                Key := 7;         { First key number = 8 }
                BuildKeywords(Name);
                BuildKeywords(Company);
                BuildKeywords(Title);
                BuildKeywords(Address);
                BuildKeywords(State);
                BuildKeywords(Country);
            END;
        END;
    END;

    {--------------------------------------------------------------------}

    PROCEDURE DeleteAllKeys(CardContents : CardIndexPtr);
    VAR
        I, J, Key, TV  : INTEGER;
        CardID         : STRING[8];
    CONST
        Delims         : SET OF CHAR = [' ', '-'];

    BEGIN
        WITH CardContents^ DO BEGIN
            IF CardIndex^.LastBtStatus = 0 THEN BEGIN
                DeleteKey(2, Pack(City));
                DeleteKey(3, Pack(State));
                DeleteKey(4, Pack(Zip));
                DeleteKey(5, Pack(Country));
                DeleteKey(6, Pack(Areacode));
                DeleteKey(7, Pack(Phone));
                FOR J := 1 TO NumKeywords DO
                    DeleteKey((J + (FirstKeyword - 1)), Keywords[J]);
            END;
        END;
    END;

    {--------------------------------------------------------------------}

    FUNCTION GenKey : STRING;
    VAR
        Done           : BOOLEAN;
        Strg           : STRING;
        C              : CHAR;
        I              : INTEGER;
    BEGIN
        Strg := '';
        FOR I := 1 TO 8 DO BEGIN
            Done := FALSE;
            REPEAT
                C := CHR(RANDOM(ORD('Z')));
                CASE C OF
                    'A'..'Z' : Done := TRUE;
                    '0'..'9' : Done := TRUE;
                END;
            UNTIL Done;
            Strg := Strg + C;
        END;                      {for}

        GenKey := Strg;
    END;

    {--------------------------------------------------------------------}

    PROCEDURE AddCardToFile(CardContents : CardIndexPtr);
    CONST
        Delims         : SET OF CHAR = [' ', '-'];
    VAR
        RecNo          : LONGINT;
        I, J, Key, TV  : INTEGER;
        Temp           : LONGINT;

    BEGIN
        IF CardIndex^.LockFile THEN BEGIN
            WITH CardContents^ DO BEGIN
                CardContents^.Rebuild := Zero;
                IF CardContents^.Name = '' THEN BEGIN
                    IF Dialog(SysMsg(001134) {'No Name!'} , 'CIX', RED, 'OK', '') = 0 THEN ;
                    CardIndex^.UnlockFile;
                    EXIT;
                END;
                CardIndex^.AddRecord(CardContents^, SIZEOF(Card_Index));
                RecNo := CardIndex^.RecordPos;
                IF CardIndex^.LastBtStatus = 0 THEN BEGIN
                    J := 0;

                    REPEAT
                        CardData^.CardId := GenKey;
                        AddKey(1, CardData^.CardID);
                        INC(J);
                    UNTIL ((CardIndex^.LastBtStatus <> 10230) OR(J > 1000));

                    IF J > 1000 THEN BEGIN
                        IF Dialog(SysMsg(001977) {'Index Error!'} , 'CIX', RED, 'OK', '') = 0 THEN ;
                        CardIndex^.UnlockFile;
                        EXIT;
                    END;

                    AddAllKeys(CardContents);

                    IF Sys^.NovellSys THEN
                        UserID := Sys^.UsersName
                    ELSE
                        UserID := 'LOCAL';

                    CardIndex^.SEEK(RecNo);
                    {ReadCard(Locked);}
                    CardIndex^.Update(CardContents^, SIZEOF(Card_Index));
                END
                ELSE BEGIN
                    IF Dialog(SysMsg(001135) {'Error Adding Card'} , 'ADD',
                              RED, 'OK', '') <> 9 THEN EXIT;
                END;
            END;
            CardIndex^.UnlockFile;
        END;
    END;

    {--------------------------------------------------------------------}

    PROCEDURE AddCard;
    BEGIN
        ESRCard^.Draw;
        ESRCard^.wFastWrite(SysMsg(001136) {'Enter Card Info'} , 1, 2, Attr(WHITE, BLUE));
        Done := FALSE;
        FILLCHAR(CardData^, SIZEOF(Card_Index), #0);
        ClearFKeys;
        WHILE NOT Done DO BEGIN
            SetTag(7, UnShift, 'ADD');
            ESRCard^.Process;
            CASE ESRCard^.GetLastCommand OF
                ccMouseDown,
                ccMouseSel :
                    {did user click on the hot spot for closing?}
                    IF HandleMousePress(ESRCard^) = hsRegion3 THEN BEGIN
                        ClearMouseEvents;
                        Done := TRUE;
                    END;
                ccDone,
                ccQuit : Done := TRUE;
                ccUser1 : ProcessHelp(ESRCard^);
                ccUser7 : BEGIN
                              AddCardToFile(CardData);
                              FILLCHAR(CardData^, SIZEOF(Card_Index), #0);
                          END;
                ccNested: EditNotes;
            END;
        END;
        ESRCard^.ERASE;
    END;

    {--------------------------------------------------------------------}
    PROCEDURE MovePreviousMenu(Item : INTEGER);
    BEGIN
        DEC(ScreenNum);
        WITH Menus[ScreenNum]^ DO BEGIN
            MoveSelection(pkChoice + Item);
            Choice := Ref^[pkChoice];
        END;
        MarkItemAsSelected;
        INC(ScreenNum);
    END;

    {--------------------------------------------------------------------}

    FUNCTION ReadCardFromMenu(Item : INTEGER) : BOOLEAN;
    VAR 
        RecNo      : LONGINT;
        Ix             : INTEGER;
    BEGIN
        ReadCardFromMenu := FALSE;
        IF NOT Str2Long(Trim(COPY(CardList^[Item], 54, 10)), RecNo) THEN EXIT;
        CardIndex^.SEEK(RecNo);
        IF CardIndex^.LastBtStatus = 0 THEN BEGIN
            ReadCard(Unlocked);
            ReadCardFromMenu := TRUE;
        END
        ELSE
            ReadCardFromMenu := FALSE;
    END;

    {-------------------------------------------------------------}

    PROCEDURE ConfigureModem;
    BEGIN
        WITH WorkStation^.Modem DO BEGIN
            AutoDial.ComPort := ComPort;
            AutoDial.Baud := CBaud[Baud];
            AutoDial.DataBits := DataBits;
            AutoDial.Parity := CParity[Parity];
            AutoDial.StopBits := StopBits;
            AutoDial.ToneDial := TRUE;
            AutoDial.Access := 0;
            AutoDial.LocalArea := '213';
            AutoDial.Emulation := VT52mode;
        END;
    END;

    {-------------------------------------------------------------}
    PROCEDURE ProcessDial(Phone_Number : STRING);
    CONST
        X        = 25;
        Y        = 10;
    VAR
        A          : STRING[6];
    BEGIN
        TextColor(RED);
        SetReplyXY(X + 12, Y);
        SetConsoleMode(TRUE);
        GotoXY(X, Y);
        IF NOT WorkStation^.Modem.Installed THEN BEGIN
            IF Dialog(SysMsg(001137) {'No Modem Installed'} , SysMsg(001083) {'DIAL'} , RED, 'OK', '') = 0 THEN ;
            EXIT;
        END;
        ConfigureModem;
        ClrEol;
        WRITE(SysMsg(001138) {'Init      '} );
        Phone_Number := CleanPhoneNumber(Phone_Number);

        GotoXY(X, Y);
        ClrEol;
        WRITE(SysMsg(001139) {'Chk Number'} );

        { if area code present, strip if local otherwise precede with '1' }
        IF LENGTH(Phone_Number) > 7 THEN BEGIN
            IF COPY(Phone_Number, 1, 3) = AutoDial.LocalArea THEN
                DELETE(Phone_Number, 1, 3)
            ELSE
                Phone_Number := '1' + Phone_Number;
        END;

        GotoXY(X, Y);
        ClrEol;
        WRITE(SysMsg(001140) {'Init Modem'} );
        WITH AutoDial DO BEGIN
            IF NOT SetUpModem(ComPort, Baud, Parity, DataBits, StopBits) THEN BEGIN
                GotoXY(X, Y);
                ClrEol;
                WRITE(SysMsg(001141) {'Error      '} );
                EXIT;
            END;

            { if code necessary to get outside line, attach code & pause }
            IF Access <> 0 THEN BEGIN
                STR(Access, A);
                Phone_Number := A + ',' + Phone_Number; { Dial access code, pause for }
            END;                  { second dial-tone, dial number }
        END;

        GotoXY(X, Y);
        ClrEol;
        WRITE(SysMsg(001067) {'Dialing'} );

        Dial_Phone(Phone_Number, AutoDial.ToneDial);

        GotoXY(X, Y);
        ClrEol;
        WRITE(SysMsg(001142) {'Disconnect'} );
        DELAY(50);
        GotoXY(X, Y);
        ClrEol;
        WRITE('         ');
        TextColor(Black);
        SetReplyXY(0, 0);
        SetConsoleMode(FALSE);
    END;

    {-------------------------------------------------------------}

    PROCEDURE ProcessRemote;
    VAR
        Phone_Number : STRING[30];
        A            : STRING[6];
    BEGIN
        ConfigureModem;

        WITH AutoDial DO BEGIN

            Phone_Number := CleanPhoneNumber(CardData^.Areacode + CardData^.Phone);

            { if area code present, strip if local otherwise precede with '1' }
            IF LENGTH(Phone_Number) > 7 THEN BEGIN
                IF COPY(Phone_Number, 1, 3) = AutoDial.LocalArea THEN
                    DELETE(Phone_Number, 1, 3)
                ELSE
                    Phone_Number := '1' + Phone_Number;
            END;

            { if code necessary to get outside line, attach code & pause }
            IF Access <> 0 THEN BEGIN
                STR(Access, A);
                Phone_Number := A + ',' + Phone_Number; { Dial access code, pause for }
            END;                  { second dial-tone, dial number }

            NormalCursor;

            { RunRemote takes over operation of Remote }
{
      TimeDisplayOn := False;
      SetupService(FindService(CardData^.Remote));
      Service^.Title := CardData^.Remote;
      Service^.Number := Phone_Number;
      RunRemote(Service^,True);
      TimeDisplayOn := True;
 }
        END;                      { with }

    END;

    {--------------------------------------------------------------------}
    PROCEDURE DisplayCard(VAR Accept : BOOLEAN);
    VAR
        I          : INTEGER;
        Cmd        : WORD;
    BEGIN
        ESRCard^.Draw;
        OldCardData^ := CardData^;
        Done := FALSE;
        Accept := FALSE;
        WHILE NOT Done DO BEGIN
            Window(32, 6, 75, 18);
            IF SecurityClearance = 3 THEN BEGIN
                ClearFKeys;
                SetTag(1, UnShift, SysMsg(000247) {'HELP'} );
                SetTag(4, UnShift, SysMsg(001083) {'DIAL'} );
                SetTag(5, UnShift, SysMsg(000826) {'DELETE'} );
                SetTag(7, UnShift, SysMsg(001143) {'UPDATE'} );
            END
            ELSE BEGIN
                SetTag(1, UnShift, SysMsg(000247) {'HELP'} );
                SetTag(4, UnShift, SysMsg(001083) {'DIAL'} );
                SetTag(5, UnShift, SysMsg(000826) {'DELETE'} );
            END;

            ESRCard^.Process;
            Cmd := ESRCard^.GetLastCommand;
            CASE Cmd OF
                ccMouseDown,
                ccMouseSel :
                    {did user click on the hot spot for closing?}
                    IF HandleMousePress(ESRCard^) = hsRegion3 THEN BEGIN
                        ClearMouseEvents;
                        Done := TRUE;
                    END;
                ccUser1 : ProcessHelp(ESRCard^);
                ccDone,
                ccUser0,
                ccQuit : Done := TRUE;
                ccUser0 : Accept := TRUE;
                ccUser4 : IF CardData^.Remote = '' THEN
                              ProcessDial(CardData^.Areacode + CardData^.Phone)
                          ELSE
                              ProcessRemote;
                ccUser5 : BEGIN
                              IF UserSaysYes(SysMsg(001144) {'Delete Card?'} , EscapeMeansNo) THEN BEGIN
                                  WITH CardIndex^ DO BEGIN
                                      DeleteAllKeys(CardData);
                                      DeleteRecord;
                                  END;
                                  Done := TRUE;
                              END;
                          END;
                ccUser7 : IF (SecurityClearance = 3) AND
                          UserSaysYes(SysMsg(001145) {'Change Card Entry?'} , EscapeMeansNo) THEN BEGIN
                              WITH CardIndex^ DO BEGIN
                                  DeleteAllKeys(OldCardData);
                                  AddAllKeys(CardData);
                                  Update(CardData^, SIZEOF(Card_Index));
                                  OldCardData^ := CardData^;
                              END;
                          END;
                ccPrevRec : BEGIN
                                IF (PgUpPgDn) AND(Found > 1) THEN BEGIN
                                    WITH Menus[ScreenNum]^ DO BEGIN
                                        IF Choice > 1 THEN BEGIN
                                            DEC(Choice);
                                            MoveSelection(Choice);
                                        END;
                                    END;
                                    IF ReadCardFromMenu(Choice) THEN ;
                                END;
                            END;
                ccNextRec : BEGIN
                                IF (PgUpPgDn) AND(Found > 1) THEN BEGIN
                                    WITH Menus[ScreenNum]^ DO BEGIN
                                        IF Choice < Size THEN BEGIN
                                            INC(Choice);
                                            MoveSelection(Choice);
                                        END;
                                    END;
                                    IF ReadCardFromMenu(Choice) THEN ;
                                END;
                            END;
                ccNested : EditNotes;
            END;
        END;
        ESRCard^.ERASE;
        ClearFKeys;
    END;

    {--------------------------------------------------------------------}
    FUNCTION GetRequestedKey(Num : WORD) : STRING;
    BEGIN
        WITH SearchMask^ DO
            CASE Num OF
                1 : GetRequestedKey := '';
                2 : GetRequestedKey := Trim(Pack(City));
                3 : GetRequestedKey := Trim(Pack(State));
                4 : GetRequestedKey := Trim(Pack(Zip));
                5 : GetRequestedKey := Trim(Pack(Country));
                6 : GetRequestedKey := Trim(Pack(Areacode));
                7 : GetRequestedKey := Trim(Pack(Phone));
                8 : GetRequestedKey := Trim(Keywords[1]);
                9 : GetRequestedKey := Trim(Keywords[2]);
                10 : GetRequestedKey := Trim(Keywords[3]);
                11 : GetRequestedKey := Trim(Keywords[4]);
                12 : GetRequestedKey := Trim(Keywords[5]);
                ELSE
                    GetRequestedKey := '';
            END;
    END;

    {--------------------------------------------------------------------}
    FUNCTION GetCardKey(Num : WORD) : STRING;
    BEGIN
        WITH CardData^ DO
            CASE Num OF
                1 : GetCardKey := CardID;
                2 : GetCardKey := Pack(City);
                3 : GetCardKey := Pack(State);
                4 : GetCardKey := Pack(Zip);
                5 : GetCardKey := Pack(Country);
                6 : GetCardKey := Pack(Areacode);
                7 : GetCardKey := Pack(Phone);
                8..TotalKeys : GetCardKey := Keywords[Num - 7];
            END;
    END;

    {--------------------------------------------------------------------}
    PROCEDURE DisplayCount(Msg : TitleString; Len : INTEGER);
    BEGIN
        SetBorderColors;
        WITH Coords[ScreenNum]^ DO BEGIN
            wFrame.AddHeader(LeftPad(Msg, Len), heBR);
            wFrame.UpdateFrame;
        END;
    END;

    {-----------------------------------------------------------}
    PROCEDURE SelectPrinter(VAR QID : LONGINT);
    VAR
        I          : INTEGER;
        First      : BOOLEAN;
        Fs         : AnyString;
    BEGIN

        QID := 0;

        { Display list of Network Print queues }
        Menu^[1] := 'LOCAL';
        I := 1;
        IF Sys^.NovellSys THEN BEGIN
            First := TRUE;
            REPEAT
                UData^.WorkS := NextBinderyObject(3, First);
                First := FALSE;
                IF UData^.WorkS <> '' THEN BEGIN
                    INC(I);
                    Menu^[I] := UData^.WorkS;
                END;
            UNTIL UData^.WorkS = '';
        END;

        IF I = 1 THEN EXIT;

        OpenMenu(WinX + 4, WinY + 2, WinX + 16, WinY + 12, Menu^, I, 12, NoSort, '',
                 SysMsg(000751) {' Select Printer '} , Copyright_Scheme, I);
        I := GetMenu;
        CloseWindow;
        IF I > 0 THEN BEGIN
            Fs := Menu^[I];
            IF I > 2 THEN
                QID := GetQid(Fs, 3);
        END
        ELSE BEGIN
            Fs := '';
            QID := - 1;
        END;
    END;

    {--------------------------------------------------------------------}

    PROCEDURE PrintCards(Format : INTEGER);
    VAR
        I          : INTEGER;
    BEGIN
        OpenMessage(SysMsg(000350) {'Printing...'} , BrightYellow_Scheme);
        CASE Format OF
            1 : WRITELN(Lst, PrintSelectHeading);
            2 : WRITELN(Lst, PrintGetCardHeading);
        END;
        FOR I := 1 TO Found DO
            WRITELN(Lst, COPY(CardList^[I], 1, 53));
        CloseMessage;
    END;

    {--------------------------------------------------------------------}

    PROCEDURE PrintSelectedCards(Format : INTEGER);
    VAR
        QID            : LONGINT;
    BEGIN
        SelectPrinter(QID);
        IF QID = - 1 THEN EXIT;
        IF QID = 0 THEN BEGIN
            PrintCards(Format);
        END
        ELSE BEGIN
            IF SetCapturePrintQueue(0, QID, 65, TRUE) THEN BEGIN
                IF StartCapture(0) THEN
                    PrintCards(Format);
                IF EndCapture(0) THEN ;
            END;
        END;
    END;

    {--------------------------------------------------------------------}
    PROCEDURE BuildRow(VAR RR         : RowRec;
                       KeyNr          : INTEGER;
                       VAR DatS;
                       DatLen         : WORD);
    BEGIN
        WITH RR, Card_Index(DatS) DO BEGIN
            Row := Pad(Name, 30) + ' (' +
                   Pad(Areacode, 3) + ')' +
                   Pad(Phone, 10);
        END;
    END;

    {--------------------------------------------------------------------}
    PROCEDURE DisplayRow(VAR RR : RowRec; KeyNr, RowNr, StartRow : INTEGER;
                         HighLight : BOOLEAN; VAR HorizOfs : INTEGER);
    VAR
        Atr        : BYTE;
    BEGIN
        WITH RR DO BEGIN
            Atr := NENColorSet.FieldColor;
            IF HighLight THEN
                Atr := NENColorSet.SelFieldColor;
            WriteStr(WinX + 5, WinY + StartRow + RowNr - 1, Row, Atr);
        END;
    END;

    {--------------------------------------------------------------------}
    PROCEDURE ListCards;
    VAR
        Index          : WORD;
        Xpos, Ypos, YDepth : INTEGER;
        DataLen        : WORD;
        Selected       : LONGINT;
        KeyStr         : IsamKeyStr;
        ExitKey        : Bktype;
        Result         : INTEGER;
        Done           : BOOLEAN;
        Security       : INTEGER;
    BEGIN
        Xpos := 14;
        Ypos := 7;
        YDepth := 11;
        IF CardIndex^.NumRecs - 1 < YDepth THEN
            YDepth := CardIndex^.NumRecs;
        OpenWindow(Xpos, Ypos, Xpos + 60, Ypos + YDepth, SysMsg(001146) {' All Cards '} , Red_Scheme);
        Coords[ScreenNum]^.AdjustFrameCoords(Xpos - 1, Ypos - 1, Xpos + 60, Ypos + YDepth + 1);

        Index := 8;               { List by Name}
        Done := FALSE;
        Selected := 1;
        KeyStr := '';
        WHILE NOT Done DO BEGIN
            PgUpPgDn := FALSE;
            BrowseKeyPtr := @UKey.GetKey;
            ExitKey := BkNone;
            Coords[ScreenNum]^.wFastWrite(SelectHeading, 1, 2, Attr(RED, LightRed));
            DisplayCount(Long2Str(CardIndex^.NumRecs - 1) + SysMsg(001147) {' Cards'} , 11);
            Result := Browse(CardIndex^.FB,
                             FALSE, { has variable recs }
                             Index, { Key #             }
                             '', #255, { Low, High key     }
                             2, YDepth, { Start, Num rows   }
                             CardData^, { Data buffer       }
                             DataLen, { length returned   }
                             Selected, { item # selected   }
                             KeyStr, { key selected      }
                             ExitKey, { Key used to exit  }
                             NIL, { Special task      }
                             @BuildRow, { Build row proc.   }
                             @DisplayRow); { Display Row proc. }
            IF Result = 0 THEN BEGIN
                IF ExitKey <> BkQuit THEN BEGIN
                    Security := SecurityClearance;
                    SecurityClearance := 1; { Cannot update from browse }
                    DisplayCard(Done);
                    SecurityClearance := Security;
                END
                ELSE
                    Done := TRUE;
            END
            ELSE
                Done := TRUE;
        END;
        CloseWindow;
        PgUpPgDn := TRUE;
    END;

    {--------------------------------------------------------------------}

    PROCEDURE FindPrimaryKey(VAR Index : WORD);
    BEGIN
        WITH SearchMask^ DO BEGIN
            Index := 2;
            IF Trim(City) = '' THEN
                INC(Index)
            ELSE EXIT;
            IF Trim(State) = '' THEN
                INC(Index)
            ELSE EXIT;
            IF Trim(Zip) = '' THEN
                INC(Index)
            ELSE EXIT;
            IF Trim(Country) = '' THEN
                INC(Index)
            ELSE EXIT;
            IF Trim(Areacode) = '' THEN
                INC(Index)
            ELSE EXIT;
            IF Trim(Phone) = '' THEN
                INC(Index)
            ELSE EXIT;
            IF Trim(Keywords[1]) = '' THEN
                INC(Index)
            ELSE EXIT;
            IF Trim(Keywords[2]) = '' THEN
                INC(Index)
            ELSE EXIT;
            IF Trim(Keywords[3]) = '' THEN
                INC(Index)
            ELSE EXIT;
            IF Trim(Keywords[4]) = '' THEN
                INC(Index)
            ELSE EXIT;
            IF Trim(Keywords[5]) = '' THEN
                Index := 0;
        END;
    END;

    {-------------------------------------------------------------}

    PROCEDURE SetFieldCount;
    VAR
        I          : INTEGER;
    BEGIN
        FieldsRequested := 0;
        FOR I := 1 TO TotalKeys DO
            IF GetRequestedKey(I) <> '' THEN
                INC(FieldsRequested);
    END;

    {-------------------------------------------------------------}
    PROCEDURE ReadAndDisplayCard(Select : INTEGER);
    VAR
        RecNo      : LONGINT;
        Done           : BOOLEAN;
    BEGIN
        IF ReadCardFromMenu(Select) THEN
            DisplayCard(Done)
        ELSE BEGIN
            IF Dialog(SysMsg(000810) {'Search Error on '} + Trim(COPY(CardList^[Select], 11, 31)), SysMsg(000811) {'READ'} ,
                      RED, 'Ok', '') = 0 THEN ;
        END;
    END;

    {-------------------------------------------------------------}

    FUNCTION CompareStrings(Key1, Key2 : KeyWordSt) : BOOLEAN;
    VAR
        Result     : BOOLEAN;
    BEGIN
        IF Key1[LENGTH(Key1)]IN['*', '?'] THEN BEGIN
            DELETE(Key1, LENGTH(Key1), 1);
        END;
        Key1 := Trim(Key1);
        Key2 := Trim(Key2);
        CASE Match OF
            ' ' : Result := Key1 = Key2;
            '*' : Result := POS(Key1, Key2) <> 0;
            '?' : Result := Soundex(Key1) = Soundex(Key2);
        END;
        CompareStrings := Result;
    END;

    {-------------------------------------------------------------}

    FUNCTION CompareKeys(Key : INTEGER; Key1, Key2 : KeyWordSt) : BOOLEAN;
    BEGIN
        CompareKeys := CompareStrings(Key1, Unpack6BitKeyUC(Key2));
    END;

    {-------------------------------------------------------------}
    PROCEDURE SearchKey(TKey : INTEGER; VAR First : BOOLEAN;
                        Key : KeyWordSt; VAR Done : BOOLEAN);
    BEGIN
        UpdateTime(FALSE);
        IF First THEN BEGIN
            Match := ' ';
            IF Key[LENGTH(Key)]IN['*', '?'] THEN BEGIN
                Match := Key[LENGTH(Key)];
                DELETE(Key, LENGTH(Key), 1);
            END;
            IF Match = ' ' THEN
                CardIndex^.Find(Pack6BitKeyUC(Key, KeySize(KeyLength[TKey])), TKey)
            ELSE
                CardIndex^.Search(Pack6BitKeyUC(Key, KeySize(KeyLength[TKey])), TKey);
            First := FALSE;
        END
        ELSE BEGIN
            CardIndex^.Next;
        END;
        IF (CardIndex^.LastBtStatus <> 0) OR
        (NOT CompareKeys(TKey, Key, CardIndex^.LastKey)) THEN BEGIN
            Done := TRUE;
        END
        ELSE BEGIN
            Matrix^.Add(CardIndex^.Position);
            IF Matrix^.Overflow THEN BEGIN
                StopTimer;
                IF Dialog(SysMsg(001148) {'Too many Cards in search!'} , SysMsg(000794) {'SEARCH'} , RED, 'Ok', '') = 0 THEN ;
                Done := TRUE;
                ReStartTimer;
                EXIT;
            END;
            IF FilterMode THEN
                WriteCentred(3, SysMsg(000813) {'Filtering: '} + Pad(Long2Str(Matrix^.Filtered), 6))
            ELSE
                WriteCentred(3, SysMsg(000814) {'Possible : '} + Pad(Long2Str(Matrix^.Found), 6));
            Done := FALSE;
        END;
    END;

    {--------------------------------------------------------------------}

    PROCEDURE DeleteItem(Num : INTEGER);
    VAR
        Key        : INTEGER;
        RecNo      : LONGINT;
    BEGIN
        MoveSelection(Num);
        IF NOT Str2Long(Trim(COPY(CardList^[Num], 54, 10)), RecNo) THEN
            EXIT;
        CardIndex^.SEEK(RecNo);
        ReadCard(Locked);
        IF CardIndex^.LastBtStatus = 0 THEN BEGIN
            DeleteAllKeys(CardData);
            IF CardData^.Rebuild = Zero THEN BEGIN
                CardIndex^.DeleteRecord;
                IF CardIndex^.LastBtStatus <> 0 THEN
                    IF Dialog(SysMsg(000194) {'Error '} + Long2Str(CardIndex^.LastBtStatus),
                              SysMsg(000826) {'DELETE'} , RED, 'OK', '') = 0 THEN ;
            END
            ELSE BEGIN
                IF Dialog(SysMsg(000827) {'Already Deleted!'} , SysMsg(000826) {'DELETE'} , Magenta, 'OK', '') = 0 THEN ;
            END;
        END;
    END;

    {-------------------------------------------------------------}
    { Get name of desired card index, and open it }

    PROCEDURE SelectCardIndex;
    VAR
        Res            : WORD;
        Num            : INTEGER;
        DirSize        : INTEGER;
        Choice         : WORD;
        Public         : WORD;
    BEGIN
        IF NOT CheckMailQueue(GetUserName) THEN BEGIN
            IF Dialog(GetUserName + SysMsg(000969) {' not found!'} , 'CIX', RED, 'OK', '') = 1 THEN ;
            EXIT;
        END;
        DirSize := 0;
        BuildDirectory(NEN^.PublicDir + '\*.CIX', TRUE, AnyFile, UGlobal.Menu^, DirSize);
        Public := DirSize;
        BuildDirectory(NEN^.PrivateDir + '\' + GetUserName + '\PRIVATE\*.CIX', TRUE, AnyFile,
                       UGlobal.Menu^[DirSize + 1], Num);
        DirSize := DirSize + Num;
        IF DirSize = 0 THEN BEGIN
            IF Dialog(SysMsg(001149) {'No Card Index found!'} ,
                      'CIX', RED, SysMsg(000975) {'CREATE'} ,
                      SysMsg(000660) {'QUIT'} ) = 1 THEN
                CreateCardFile;
            EXIT;
        END;
        IF DirSize = 1 THEN BEGIN
            IF Public = 0 THEN
                CardPath := NEN^.PrivateDir + '\' + GetUserName + '\PRIVATE'
            ELSE
                CardPath := NEN^.PublicDir;
            CardIndexName := UGlobal.Menu^[1];
            OpenCardIndex;
            EXIT;
        END;
        OpenMenu(18, 7, 62, 19, Menu^, DirSize, 8, Sort, '', SysMsg(001150) {'Card Files'} , Mauve_Scheme, Num);
        Choice := GetMenu;
        CloseWindow;
        IF Choice > 0 THEN BEGIN
            IF Choice > Public THEN
                CardPath := NEN^.PrivateDir + '\' + GetUserName + '\PRIVATE'
            ELSE
                CardPath := NEN^.PublicDir;
            CardIndexName := UGlobal.Menu^[Choice];
            OpenCardIndex;
        END;
    END;

    {--------------------------------------------------------------------}
    PROCEDURE DoSearch;

    VAR
        Index          : WORD;
        Xpos,
        Ypos,
        YDepth         : INTEGER;
        DataLen        : WORD;
        Selected       : LONGINT;
        KeyStr         : IsamKeyStr;
        ExitKey        : Bktype;
        I,
        J              : INTEGER;
        Done           : BOOLEAN;
        SearchDone     : BOOLEAN;
        Hit            : BOOLEAN;
        HitCount       : WORD;
        First          : BOOLEAN;
        Key            : KeyWordSt;
        KeyNum         : INTEGER;
        TestKey        : INTEGER;
        KeyDone        : BOOLEAN;
        SubSearchDone  : BOOLEAN;
        SelectMenuUp   : BOOLEAN;
        MatchMenuUp    : BOOLEAN;
        ValidSelection : BOOLEAN;
        Match          : CHAR;
        ExactFound     : WORD;
        CloseFound     : WORD;
        LooseFound     : WORD;

    LABEL StartSearch, DisplaySelections, EndSearch;

    BEGIN

        FindPrimaryKey(Index);
        IF Index = 0 THEN BEGIN
            IF Dialog(SysMsg(000829) {'Must select at least 1 key'} , SysMsg(000794) {'SEARCH'} , RED, 'OK', '') = 0 THEN ;
            EXIT;
        END;

        ResetTimer;
        StartTimer;

        OpenMessage(SysMsg(000830) {' Searching for '} + Pad(GetRequestedKey(Index), 15), BrightYellow_Scheme);

        SetFieldCount;
        SearchMode := Strict;
        Found := 0;
        Matrix^.RESET;


        { Multi-key matrix search. Searches by each requested key & builds }
        { a matrix of each record found & number of times it was hit.      }

        KeyNum := 12;
        SearchDone := FALSE;
        WHILE NOT SearchDone DO BEGIN
            UpdateTime(FALSE);
        {$B+}
            IF (KeyNum < FirstKeyword) AND(Matrix^.Found > 0) THEN
                FilterMode := TRUE
            ELSE
                FilterMode := FALSE;
        {$B-}
            IF GetRequestedKey(KeyNum) <> '' THEN BEGIN
                WriteCentred(2, SysMsg(000830) {' Searching for '} + Pad(GetRequestedKey(KeyNum), 15));
                Key := GetRequestedKey(KeyNum);
                KeyDone := FALSE;
                First := TRUE;
                WHILE NOT KeyDone DO BEGIN
                    IF MEM[$40:$17]AND $08 <> 0 THEN { <Alt> }
                        IF Dialog( SysMsg(000831) {'End Search Now?'} ,
                                   SysMsg(000794) {'SEARCH'} ,
                                   GREEN,
                                   SysMsg(64),
                                   SysMsg(65)) = 1 THEN BEGIN
                            KeyDone := TRUE;
                            SearchDone := TRUE;
                        END;
                    IF KeyNum < FirstKeyword THEN
                        SearchKey(KeyNum, First, Key, KeyDone)
                    ELSE BEGIN
                        FOR TestKey := FirstKeyword TO TotalKeys DO BEGIN
                            SubSearchDone := FALSE;
                            First := TRUE;
                            WHILE NOT SubSearchDone DO BEGIN
                                SearchKey(TestKey, First, Key, SubSearchDone);
                                IF MEM[$40:$17]AND $08 <> 0 THEN { <Alt> }
                                    IF Dialog(SysMsg(000831) {'End Search Now?'} ,
                                              SysMsg(000794) {'SEARCH'} , GREEN, SysMsg(64), SysMsg(65)) = 1 THEN BEGIN
                                        KeyDone := TRUE;
                                        SearchDone := TRUE;
                                        SubSearchDone := TRUE;
                                    END;
                            END;
                        END;
                        KeyDone := TRUE;
                    END;
                END;
            END;
            DEC(KeyNum);
            IF KeyNum < 1 THEN
                SearchDone := TRUE;
        END;

        MatchMenuUp := FALSE;

        { Matrix built. Now, each record in the matrix that has a hit count }
        { equal to the number of requested keys is a AND mode match.        }
        { Every record is a OR mode match.                                  }

StartSearch: { Back here for relaxed search }

        IF Matrix^.Found = 0 THEN BEGIN
            StopTimer;
            Choice := Dialog(SysMsg(001151) {'No Matching Cards'} , SysMsg(000794) {'SEARCH'} , LightRed, 'OK', '');
            CloseMessage;
            EXIT;
        END;

        CloseMessage;

        IF FieldsRequested > 1 THEN BEGIN
            ExactFound := 0;
            CloseFound := 0;
            LooseFound := 0;
            FOR I := 1 TO Matrix^.Found DO BEGIN
                Matrix^.GetElement(I, Selected, HitCount);
                IF HitCount = FieldsRequested THEN
                    INC(ExactFound)
                ELSE
                    IF (HitCount >= (FieldsRequested DIV 2)) AND(HitCount > 1) THEN
                        INC(CloseFound)
                ELSE
                    IF HitCount >= 1 THEN
                        INC(LooseFound);
            END;


            IF LooseFound + CloseFound > 0 THEN BEGIN
                StopTimer;
                Menu^[1] := SysMsg(000835) {'Exact match on '} + Long2Str(ExactFound) + SysMsg(001147) {' Cards'} ;
                Menu^[2] := SysMsg(000836) {'Close match on '} + Long2Str(CloseFound) + SysMsg(001147) {' Cards'} ;
                Menu^[3] := SysMsg(000837) {'Some  match on '} + Long2Str(LooseFound) + SysMsg(001147) {' Cards'} ;
                IF NOT MatchMenuUp THEN BEGIN
                    OpenMenu(34, 5, 69, 11, Menu^, 3, 30, NoSort, ''
                             , SysMsg(000839) {'Match Result'} , Black_Scheme, I);
                    WITH Menus[ScreenNum]^ DO
                        AddComment(Long2Str(Matrix^.Found) + SysMsg(000838) {' Hits'} ,
                                   0, 1);
                    IF ExactFound <> 0 THEN { Pop exact menu up first time }
                        StuffKey(OpKey.Enter);
                END;
                MatchMenuUp := TRUE;
                ValidSelection := FALSE;
                WHILE NOT ValidSelection DO BEGIN
                    CASE GetMenu OF
                        0 : BEGIN
                                CloseWindow;
                                MatchMenuUp := FALSE;
                                EXIT;
                            END;
                        1 : BEGIN
                                IF ExactFound > 0 THEN
                                    ValidSelection := TRUE;
                                SearchMode := Strict;
                            END;
                        2 : BEGIN
                                IF CloseFound > 0 THEN
                                    ValidSelection := TRUE;
                                SearchMode := Relaxed;
                            END;
                        3 : BEGIN
                                IF LooseFound > 0 THEN
                                    ValidSelection := TRUE;
                                SearchMode := Loose;
                            END;
                    END;
                END;
            END;
        END;
        OpenMessage(SysMsg(001152) {'Reading & Selecting Cards'} , BrightYellow_Scheme);

        Found := 0;
        FOR I := 1 TO Matrix^.Found DO BEGIN
            UpdateTime(FALSE);
            Matrix^.GetElement(I, Selected, HitCount);
            Hit := FALSE;
            CASE SearchMode OF
                Strict : BEGIN    { Only those matching all keys }
                             IF FieldsRequested = HitCount THEN
                                 Hit := TRUE;
                         END;
                Relaxed : BEGIN   { match more than one but not all }
                              IF (HitCount >= (FieldsRequested DIV 2)) THEN
                                  Hit := TRUE;
                          END;
                Loose : BEGIN     { match any key }
                            IF (HitCount > 0) THEN
                                Hit := TRUE;
                        END;
            END;
            IF Hit THEN BEGIN
                CardIndex^.SEEK(Selected);
                ReadCard(Unlocked);
                INC(Found);
                IF Found > CardListSize THEN BEGIN
                    StopTimer;
                    IF Dialog(SysMsg(001153) {'Too many Cards!, Narrow search'} , SysMsg(000794) {'SEARCH'} , RED,
                              'OK', '') = 0 THEN ;
                    DEC(Found);
                    GOTO DisplaySelections;
                END;
                WriteCentred(2, SysMsg(000820) {'Found: '} + Pad(Long2Str(Found), 6));
                CardList^[Found] := Pad(CardData^.Name, 30) + ' (' +
                                    Pad(CardData^.Areacode, 3) + ')' +
                                    Pad(CardData^.Phone, 10);
                CardList^[Found] := Pad(CardList^[Found], 53) + Long2Str(Selected);
            END;
        END;

        StopTimer;
DisplaySelections:

        CloseMessage;

        Xpos := 14;
        Ypos := 10;
        YDepth := 10;
        IF Found < YDepth THEN
            YDepth := Found + 1;

        Choice := 1;
        SelectMenuUp := FALSE;

        IF Found = 1 THEN BEGIN
            IF CardIndex^.LastBtStatus = 0 THEN BEGIN
                ReadAndDisplayCard(1);
            END;
            GOTO EndSearch;
        END;

        IF Found = 0 THEN GOTO EndSearch;

        OpenMenu(Xpos, Ypos - 1, Xpos + 60, Ypos + YDepth, CardList^, Found, 53, Sort,
                 SelectHeading,
                 SysMsg(001154) {' Selected Cards '} , Red_Scheme, I);

        DisplayCount(Long2Str(Found) + SysMsg(001147) {' Cards'} , 11);

        TextAttr := Attr(RED, LightCyan);
        ClearFKeys;
        SetTag(6, UnShift, SysMsg(000750) {'PRINT'} );

        SelectMenuUp := TRUE;

        EnableFunctionKeyExit := TRUE;
        WHILE NOT EscapePressed DO BEGIN
            Choice := GetMenu;
            IF Choice <> 0 THEN BEGIN
                IF Choice < 1000 THEN
                    ReadAndDisplayCard(Choice)
                ELSE BEGIN
                    IF Choice DIV 1000 = 6 THEN
                        PrintSelectedCards(1);
                END;
            END;
        END;
        EnableFunctionKeyExit := FALSE;

EndSearch:

        IF SelectMenuUp THEN
            CloseWindow;
        SelectMenuUp := FALSE;

        IF MatchMenuUp THEN
            GOTO StartSearch;

    END;

    {--------------------------------------------------------------------}
    FUNCTION BuildaKey(VAR DatS; KeyNr : INTEGER) : IsamKeyStr;
    BEGIN
        MOVE(DatS, CardData^, SIZEOF(Card_Index));
        IF CardData^.Rebuild <> Zero THEN BEGIN
            BuildaKey := '';
            EXIT;
        END;
        WriteCentred(2, Pad(SysMsg(001155) {'Idx '} + Pad(GetCardKey(KeyNr), 30), 35));
        BuildaKey := Pack6BitKeyUC(GetCardKey(KeyNr), KeySize(KeyLength[KeyNr]));
    END;

    {--------------------------------------------------------------------}

    FUNCTION ConvertRec(VAR OldRec:Card_Index; VAR DatSnew:Card_Index; Dummy : WORD) : BOOLEAN;
    VAR
       {OldRec     : Card_Index ABSOLUTE DatSold;}
       J,
       Key        : WORD;
    CONST
        Delims         : SET OF CHAR = [' ', '-', '/', ',', '.'];

        FUNCTION DuplicateKey(VAR KeyWord : KeyWordSt; Num : INTEGER) : BOOLEAN;
        VAR 
            I          : INTEGER;
        BEGIN
            WITH OldRec DO BEGIN
                FOR I := 1 TO NumKeywords DO
                    IF I <> Num THEN
                        IF Trim(KeyWord) = Trim(Keywords[I]) THEN BEGIN
                            KeyWord := '';
                            DuplicateKey := TRUE;
                            EXIT;
                        END;
                DuplicateKey := FALSE;
            END;
        END;

        PROCEDURE BuildKeywords(Wd : STRING);
        VAR
            I          : INTEGER;
        BEGIN
            WITH OldRec DO BEGIN
                FOR I := 1 TO WordCount(Wd, Delims) DO BEGIN
                    INC(Key);
                    INC(J);
                    IF Key <= TotalKeys THEN BEGIN
                        Keywords[J] := Pack(ExtractWord(I, Wd, Delims));
                        IF (LENGTH(Keywords[J]) > 1) AND(NOT DuplicateKey(Keywords[J], J)) THEN
                            {                    AddKey(Key,Keywords[J])}
                        ELSE
                            DEC(J);
                    END
                END;
            END;
        END;

    BEGIN
        J := 0;                   { First computed keyword offset is 1 }
        Key := 7;                 { First key number = 8 }
        WITH OldRec DO BEGIN
            BuildKeywords(Name);
            BuildKeywords(Company);
            BuildKeywords(Title);
            BuildKeywords(Address);
            BuildKeywords(State);
            BuildKeywords(Country);
        END;
        MOVE(OldRec, DatSnew, SIZEOF(Card_Index));
        IF (OldRec.Rebuild <> Zero) OR(Trim(OldRec.Name) = '') THEN BEGIN
            WriteCentred(2, Pad(SysMsg(001156) {'Del '} + Pad(OldRec.Name, 30), 35));
            ConvertRec := FALSE;
        END
        ELSE BEGIN
            WriteCentred(2, Pad(SysMsg(001157) {'Add '} + Pad(OldRec.Name, 30), 35));
            ConvertRec := TRUE;
        END;
    END;

    {--------------------------------------------------------------------}
    PROCEDURE RebuildLibrary;
    VAR
        I          : INTEGER;
        Size           : LONGINT;
    BEGIN
        Menu^[1] := SysMsg(000064) {'Yes '} ;
        Menu^[2] := SysMsg(000856) {'DOS (Yes)'} ;
        Menu^[3] := SysMsg(65);
        DosExit := FALSE;
        CASE AskUser(27, 9,       { x1,y1,x2,y2 }
                     SysMsg(000855) {'Rebuild Database?'} ,
                     SysMsg(000857) {'REBUILD'} , { as for Dialog }
                     White_Scheme, { main colors }
                     BLUE,        { Title background }
                     Brown,       { Box background }
                     LightBlue,   { First letter }
                     BLUE,        { Remaining letters }
                     3,           { Number of items }
                     Menu^) OF    { item list }
            0, 3 : EXIT;
            2 : DosExit := TRUE;
        END;
        OpenMessage(SysMsg(000858) {'Rebuilding..Please Wait'} , Yellow_Scheme);
        DefineCardIndexKeys;
        MOVE(CardIndex^.IID, IID, SIZEOF(IsamIndDescr));
        AutoAllocate := FALSE;
        CloseCardIndex;
        Filer.DatExtension := 'CIX';
        Size := SIZEOF(Card_Index);
        CASE Dialog('Rebuild Mode', 'CIX', GREEN, 'Rebuild', 'Reindex') OF
            1 : ReorgFileBlock(CardPath + '\' + CardIndexName,
                               Size,
                               TotalKeys,
                               IID,
                               Size,
                               @UCard.BuildaKey,
                               @UCard.ConvertRec);

            2 : ReIndexFileBlock(CardPath + '\' + CardIndexName,
                                 Size,
                                 TotalKeys,
                                 IID,
                                 @UCard.BuildaKey);
        END;
        CloseMessage;
        IF DosExit THEN BEGIN
            StuffKey($011B);
            StuffKey($011B);
        END;
        OpenCardIndex;
        AutoAllocate := TRUE;
    END;

(*
{--------------------------------------------------------------------}
procedure RebuildLibrary;
  var 
    I: integer;
      Size: LongInt;
  begin
    if not UserSaysYes(SysMsg(001158){'Rebuild '}+CardIndexName+'?',EscapeMeansNo) then exit;
    OpenMessage(SysMsg(000858){'Rebuilding..Please Wait'},Yellow_Scheme);
    DefineCardIndexKeys;
    Move(CardIndex^.IID,IID,SizeOf(IsamIndDescr));
    AutoAllocate := False;
    CloseCardIndex;
    Size := SizeOf(Card_Index);
    ReOrgFileBlock(CardPath+'\'+CardIndexName,
                   Size,
                   TotalKeys,
                   IID,
                   Size,
                   @UCard.BuildaKey,
                   @UCard.ConvertRec);
    CloseMessage;
    OpenCardIndex;
    AutoAllocate := True;
  end;
*)
    {--------------------------------------------------------------------}

    PROCEDURE MemoryFail;
    BEGIN
        WRITELN(SysMsg(000859) {'Not enough memory!'} );
        HALT(1);
    END;

    {--------------------------------------------------------------------}

    PROCEDURE AllocateMemory;
    BEGIN
        NEW(SearchMask);
        IF SearchMask = NIL THEN
            MemoryFail;
        NEW(CardData);
        IF CardData = NIL THEN
            MemoryFail;
        NEW(OldCardData);
        IF OldCardData = NIL THEN
            MemoryFail;
        NEW(CardList);
        IF CardList = NIL THEN
            MemoryFail;
        NEW(Matrix);
        IF Matrix = NIL THEN
            MemoryFail;
        Matrix^.Init;
        AreaCodes := NIL;
    END;

    {--------------------------------------------------------------------}

    PROCEDURE DeAllocateMemory;
    BEGIN
        DISPOSE(CardList);
        DISPOSE(ESRSearch, Done);
        DISPOSE(ESRCard, Done);
        DISPOSE(CardData);
        DISPOSE(OldCardData);
        DISPOSE(SearchMask);
        Matrix^.Done;
        DISPOSE(Matrix);
        IF AreaCodes <> NIL THEN
            FreeMemCheck(AreaCodes, AreaCodeSize);
    END;

    {--------------------------------------------------------------------}

    PROCEDURE SetSecurityLevel;
    VAR
        NetPathBase,
        BaseFlags,
        Rights,
        DirRights,
        StationRights : BYTE;
        DrvPathMap     : NovellPath;
        CurDir         : PathStr;
        Drive,
        Flags   : BYTE;
    BEGIN
        GETDIR(0, CurDir);
        IF (UPCASE(CurDir[1]) IN['A'..'E']) OR(NOT Sys^.NovellSys) THEN BEGIN
            IF SecurityRequested <> 0 THEN
                SecurityClearance := SecurityRequested
            ELSE
                SecurityClearance := 3; { Top level if local }
            EXIT;
        END
        ELSE BEGIN
            Drive := GetDirHandle(CurDir[1], Flags);
            GetDriveBaseMap(Drive, NetPathBase, BaseFlags);
            GetDirPath(Drive, CurDir);
            IF GetDirRights(Drive, CurDir, Rights) = 0 THEN ;

            IF Rights AND 128 <> 0 THEN SecurityClearance := 3 { M }
            ELSE IF Rights AND 32 <> 0 THEN SecurityClearance := 2 { P }
            ELSE SecurityClearance := 1;
        END;
    END;

    {--------------------------------------------------------------------}

    PROCEDURE FileMaintenance;
    VAR
        I          : INTEGER;
    BEGIN
        Menu^[1] := SysMsg(001159) {'Create New File'} ;
        Menu^[2] := SysMsg(001160) {'Rebuild Damaged File'} ;
        Menu^[3] := SysMsg(001078) {'Delete File'} ;
        OpenMenu(WinX + 4, WinY + 2, WinX + 32, WinY + 7, Menu^, 3, 20, NoSort, '', SysMsg(001161) {' Maintenance '} ,
                 Cyan_Scheme, I);
        WHILE NOT EscapePressed DO BEGIN
            CASE GetMenu OF
                1 : CreateCardFile;
                2 : RebuildLibrary;
            END;
        END;
        CloseWindow;
    END;

    {--------------------------------------------------------------------}
    PROCEDURE SearchCardIndex;
    VAR
        M,
        I       : INTEGER;
    BEGIN

        AllocateMemory;

        SavePrompt;
        UData^.PromptLine := 0;
        OpenFKeyDisplay(23);

        InitEntryScreen;

        RANDOMIZE;
        SetSecurityLevel;

        DeleteFlag := FALSE;
        Filer.DatExtension := 'CIX';
        UBtree.SaveMode := TRUE;
        UBtree.AutoAllocate := TRUE;

        IF NENFlag THEN
            ReserveHeapSpace(MEMAVAIL - 40000) { Give Btree 20K if under NEN }
        ELSE
            ReserveHeapSpace(MEMAVAIL - 40000); { 40K if stand-alone }

        SelectCardIndex;
        IF NOT CardIndexOpen THEN BEGIN
            IF Dialog(SysMsg(000860) {'DB Error '} + Long2Str(CardIndex^.LastBtStatus), SysMsg(001162) {'Card Library'} ,
                      RED, SysMsg(000660) {'Quit'} , SysMsg(000857) {'Rebuild'} ) = 2 THEN FileMaintenance;
            DeAllocateMemory;
            CloseFKeyDisplay;
            EXIT;
        END;

        SecurityClearance := 3;
        CASE SecurityClearance OF
            3 : BEGIN
                    Menu^[1] := SysMsg(001163) {'Search for Card'} ;
                    Menu^[2] := SysMsg(001164) {'Browse thru Cards'} ;
                    Menu^[3] := SysMsg(001165) {'Add a Card'} ;
                    Menu^[4] := SysMsg(001166) {'Select File'} ;
                    Menu^[5] := SysMsg(000867) {'Maintenance'} ;
                    Menu^[6] := SysMsg(000660) {'Quit'} ;
                    I := 6;
                END;
            2 : BEGIN
                    Menu^[1] := SysMsg(001163) {'Search for Card'} ;
                    Menu^[2] := SysMsg(001164) {'Browse thru Cards'} ;
                    Menu^[3] := SysMsg(001165) {'Add a Card'} ;
                    Menu^[4] := SysMsg(000660) {'Quit'} ;
                    I := 4;
                END;
            1 : BEGIN
                    Menu^[1] := SysMsg(001163) {'Search for Card'} ;
                    Menu^[2] := SysMsg(001164) {'Browse thru Cards'} ;
                    Menu^[3] := SysMsg(000660) {'Quit'} ;
                    I := 3;
                END;
        END;

        OpenMenu(6, 5, 25, 7 + I, Menu^, I, 17, NoSort, '', SysMsg(57), Orange_Scheme, M);
        WHILE NOT EscapePressed DO BEGIN
            M := GetMenu;
            CASE SecurityClearance OF
                3 : CASE M OF     { Can do everything }
                        1 : SearchCards;
                        2 : ListCards;
                        3 : AddCard;
                        4 : BEGIN
                                CloseCardIndex;
                                SelectCardIndex;
                            END;
                        5 : FileMaintenance;
                        6 : ForceEscape;
                    END;
                2 : CASE M OF     { Can Add & Update, but not Delete }
                        1 : SearchCards;
                        2 : ListCards;
                        3 : AddCard;
                        4 : ForceEscape;
                    END;
                1 : CASE M OF     { Can only read }
                        1 : SearchCards;
                        2 : ListCards;
                        3 : ForceEscape;
                    END;
            END;
        END;
        CloseWindow;

        CloseFKeyDisplay;

        UData^.PromptLine := 25;
        RestorePrompt;

        CloseCardIndex;

        DeAllocateMemory;

    END;

END.

(*****************************************************************************)
(*****************************************************************************)
