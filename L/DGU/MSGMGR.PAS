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
* Language specific string and hotkey management.
*
*
* ~notesend~
* ~nokeywords~
*
****************************************************************************

}

{$IFDEF VIRTUALPASCAL}
{$A+,B-,E+,F-,G+,H-,I+,N+,O+,P-,Q+,R+,S+,T-,V-,X+,Y+}
{$ELSE}
{$A+,B-,E+,F-,G+,I+,N+,O+,P-,Q+,R+,S+,T-,V-,X+,Y+}
{$ENDIF}

UNIT MSGMGR;

INTERFACE

USES
    Dos,
    OpCRT,
    OpMenu,
    SysMsg;

VAR
    ScnMsgP,
    PrnMsgP        : MsgObjP;
    StrYes,
    StrNo,
    StrTrue,
    StrFalse       : STRING[20];

FUNCTION ValidLangFile(Lang : PathStr) : BOOLEAN;
FUNCTION MsgMgrInit(ScrnLang, PrnLang : PathStr; VAR SP, PP : MsgObjP) : BOOLEAN;
    {$IFDEF VirtualPascal}
FUNCTION MsgMgrInitRES(ScrnLang, PrnLang : PChar; VAR SP, PP : MsgObjP) : BOOLEAN;
{$ENDIF}
FUNCTION MsgMgrInitDbg(ScrnLang, PrnLang : PathStr; VAR SP, PP : MsgObjP) : BOOLEAN;
FUNCTION ChangeLang(ScrnLang, PrnLang : PathStr; VAR SP, PP : MsgObjP) : BOOLEAN;
FUNCTION LookupCommand(N : LONGINT; VAR SP : MsgObjP) : WORD;
PROCEDURE InitYNTF(Y, N, T, F : LONGINT);
PROCEDURE InitYNTF2(Y, N, T, F, MYes, MNo, MTrue, MFalse : LONGINT);
FUNCTION TranslateToCurLang(Strg           : STRING; {string to translate}
                            MinMsg, {search start in CLP}
                            MaxMsg         : WORD; {search end in CLP}
                            CLP            : MsgObjP {screen or printer}
                            )              : STRING; {either same as strg or translation}
TYPE
    {object descended from Menu to allow internationalization of menu item text}
    {this object can read sysmsg strings and derive the hotletter for a given  }
    {item (if any).  A leading '&' identifies the hot letter.  No ampersand    }
    {means no menuitem hotletter                                               }
    KMenuP         = ^KMenuT;
    KMenuT         = OBJECT(Menu)
                         {-Create a menu with default options and colors}
                         CONSTRUCTOR Init(X1, Y1, X2, Y2 : BYTE;
                                          Orient         : mnOrientation);
                         CONSTRUCTOR InitCustom(X1, Y1, X2, Y2 : BYTE;
                                                VAR Colors     : ColorSet;
                                                Options        : LONGINT;
                                                Orient         : mnOrientation);
                             {-Add item to current item list, allocating string space on heap}
                         PROCEDURE KAddItem(Name : LONGINT; DisplayPos : BYTE;
                                            Key            : LONGINT);
                         PROCEDURE KAddItemPtr(Name : LONGINT; DisplayPos : BYTE;
                                               Key            : LONGINT);
                             {-Add item to current item list, not allocating string space on heap}
                         PROCEDURE KAddItemHelp(Name : LONGINT; DisplayPos : BYTE;
                                                Key : LONGINT; Help : LONGINT);
                             {-Add item to current item list, allocating string space on heap}
                         PROCEDURE KAddItemHelpPtr(Name : LONGINT; DisplayPos : BYTE;
                                                   Key : LONGINT; Help : LONGINT);
                         FUNCTION GetMaxHelpLen : BYTE;
                     PRIVATE
                         MaxHelpLen     : BYTE;
                         FUNCTION GetSelectPos(VAR Strg : STRING) : BYTE;
                     END;


CONST
    {$IFDEF LANGDEV}
    LANGREV = #3#127#8#55#47#32;
    {$ELSE}
    LANGREV        = #2#125#99#51#47#231;
    {$ENDIF}


IMPLEMENTATION
USES
    DGLIB,
    KERROR,
    OpAbsFld,
    OpCmd,
    OpDos,
    OpInline,
    OpRoot,
    OpString,
    Strings,
    UTIAM,
    UTTIMDAT;

    {------------}

    FUNCTION ValidLangFile(Lang : PathStr) : BOOLEAN;
    VAR
        MP             : MsgObjP;
    BEGIN
        ValidLangFile := FALSE;
        NEW(MP, Init(Lang, 100, LANGREV));
        IF MP = NIL THEN
            EXIT;
        ValidLangFile := TRUE;
        DISPOSE(MP, Done);
    END;

    {------------}

    {initialize the two language objects.  If only one language is used for}
    {both screen and printouts, then instantiate only one lang object and  }
    {use it for both scn and prt                                           }
    FUNCTION MsgMgrInit(ScrnLang, PrnLang : PathStr; VAR SP, PP : MsgObjP) : BOOLEAN;
        {if msg is newer than msx, then recompile msx}
        {if msg does not exist, then just exit}
        PROCEDURE MsgRefresh(Name : PathStr);
        VAR
            FG,
            FX             : FILE;
            TG,
            Tx             : LONGINT;
            MP             : MsgObjP;
            OFM            : WORD;
            Strg           : STRING;
        BEGIN
            IF ExistFile(ForceExtension(Name, 'MSG')) THEN BEGIN
                IF NOT ExistFile(ForceExtension(Name, 'MSX')) THEN BEGIN
                    NEW(MP, CreateMSX(ForceExtension(Name, 'MSX'),
                                      ForceExtension(Name, 'MSG'),
                                      LANGREV));
                    IF MP = NIL THEN
                        HALT;

                    DISPOSE(MP, Done);
                    EXIT;
                END;
                ASSIGN(FX, ForceExtension(Name, 'MSX'));
                ASSIGN(FG, ForceExtension(Name, 'MSG'));
                OFM := FILEMODE;
                FILEMODE := 0;
                {$I-}
                RESET(FX);
                Tx := IORESULT;
                IF Tx = 162 THEN BEGIN
                    FILEMODE := OFM;
                    EXIT;         {somebody else has it open already}
                END;
                IF Tx <> 0 THEN BEGIN
                    {$IFNDEF DLL}
                    DispErrorDeluxe('Problem opening ' + ForceExtension(Name, 'MSX'),
                                    ErrorMessage(Tx), TRUE, Iam);
                    {$ENDIF}
                    HALT(1);
                END;
                RESET(FG);
                Tx := IORESULT;
                IF Tx <> 0 THEN BEGIN
                    FILEMODE := OFM;
                    EXIT;
                END;
                GetFTime(FX, Tx);
                GetFTime(FG, TG);
                CLOSE(FX);
                CLOSE(FG);
                FILEMODE := OFM;
                {$I+}
                IF TG > Tx THEN BEGIN
                    NEW(MP, CreateMSX(ForceExtension(Name, 'MSX'),
                                      ForceExtension(Name, 'MSG'),
                                      LANGREV));
                    IF MP = NIL THEN
                        HALT;

                    DISPOSE(MP, Done);
                END;
            END;
        END;
    BEGIN
        MsgMgrInit := FALSE;
        MsgRefresh(ScrnLang);
        NEW(SP, Init(ScrnLang, 100, LANGREV));
        IF SP = NIL THEN BEGIN
            {$IFNDEF DLL}
            DispErrorDeluxe('Language File Error : ' + ScrnLang, ErrorMessage(InitStatus), TRUE, Iam);
            {$ENDIF}
            EXIT;
        END;

        {if screen and print language is the same then just point to}
        {same object}
        IF (ScrnLang = PrnLang) OR (PrnLang = '') THEN BEGIN
            PP := SP;
            MsgMgrInit := TRUE;
            EXIT;
        END;
        MsgRefresh(PrnLang);
        {load printer language}
        NEW(PP, Init(PrnLang, 100, LANGREV));
        IF PP = NIL THEN BEGIN
            {$IFNDEF DLL}
            DispErrorDeluxe('Language File Error : ' + PrnLang, ErrorMessage(InitStatus), TRUE, Iam);
            {$ENDIF}
            EXIT;
        END;

        MsgMgrInit := TRUE;
    END;

    {------------}
    {$IFDEF VirtualPascal}
    {initialize the two language objects.  If only one language is used for}
    {both screen and printouts, then instantiate only one lang object and  }
    {use it for both scn and prt                                           }
    FUNCTION MsgMgrInitRES(ScrnLang, PrnLang : PChar; VAR SP, PP : MsgObjP) : BOOLEAN;
    BEGIN
        MsgMgrInitRES := FALSE;
        NEW(SP, InitRES(ScrnLang));
        IF SP = NIL THEN BEGIN
            {$IFNDEF DLL}
            DispErrorDeluxe('Language RES Error : ' + StrPas(ScrnLang), ErrorMessage(InitStatus), TRUE, Iam);
            {$ENDIF}
            EXIT;
        END;

        {if screen and print language is the same then just point to}
        {same object}
        IF (StrIComp(ScrnLang, PrnLang) = 0) THEN BEGIN
            PP := SP;
            MsgMgrInitRES := TRUE;
            EXIT;
        END;

        {load printer language}
        NEW(PP, InitRES(PrnLang));
        IF PP = NIL THEN BEGIN
            {$IFNDEF DLL}
            DispErrorDeluxe('Language RES Error : ' + StrPas(PrnLang), ErrorMessage(InitStatus), TRUE, Iam);
            {$ENDIF}
            EXIT;
        END;

        MsgMgrInitRES := TRUE;
    END;

    {$ENDIF}

    {------------}

    {initialize the two language objects.  If only one language is used for}
    {both screen and printouts, then instantiate only one lang object and  }
    {use it for both scn and prt                                           }
    FUNCTION MsgMgrInitDbg(ScrnLang, PrnLang : PathStr; VAR SP, PP : MsgObjP) : BOOLEAN;
        {if msg is newer than msx, then recompile msx}
        {if msg does not exist, then just exit}
        PROCEDURE MsgRefresh(Name : PathStr);
        VAR
            FG,
            FX             : FILE;
            TG,
            Tx             : LONGINT;
            MP             : MsgObjP;
            OFM            : WORD;
            Strg           : STRING;
        BEGIN
            IF ExistFile(ForceExtension(Name, 'MSG')) THEN BEGIN
                IF NOT ExistFile(ForceExtension(Name, 'MSX')) THEN BEGIN
                    NEW(MP, CreateXSM(ForceExtension(Name, 'MSX'),
                                      ForceExtension(Name, 'MSG'),
                                      LANGREV));
                    IF MP = NIL THEN
                        HALT;

                    DISPOSE(MP, Done);
                    EXIT;
                END;
                ASSIGN(FX, ForceExtension(Name, 'MSX'));
                ASSIGN(FG, ForceExtension(Name, 'MSG'));
                OFM := FILEMODE;
                FILEMODE := 0;
                {$I-}
                RESET(FX);
                Tx := IORESULT;
                IF Tx = 162 THEN BEGIN
                    FILEMODE := OFM;
                    EXIT;         {somebody else has it open already}
                END;
                IF Tx <> 0 THEN BEGIN
                    {$IFNDEF DLL}
                    DispErrorDeluxe('Problem opening ' + ForceExtension(Name, 'MSX'),
                                    ErrorMessage(Tx), TRUE, Iam);
                    {$ENDIF}
                    HALT(1);
                END;
                RESET(FG);
                Tx := IORESULT;
                IF Tx <> 0 THEN BEGIN
                    FILEMODE := OFM;
                    EXIT;
                END;
                GetFTime(FX, Tx);
                GetFTime(FG, TG);
                CLOSE(FX);
                CLOSE(FG);
                FILEMODE := OFM;
                {$I+}
                IF TG > Tx THEN BEGIN
                    NEW(MP, CreateXSM(ForceExtension(Name, 'MSX'),
                                      ForceExtension(Name, 'MSG'),
                                      LANGREV));
                    IF MP = NIL THEN
                        HALT;

                    DISPOSE(MP, Done);
                END;
            END;
        END;
    BEGIN
        MsgMgrInitDbg := FALSE;
        MsgRefresh(ScrnLang);
        NEW(SP, Init(ScrnLang, 100, LANGREV));
        IF SP = NIL THEN BEGIN
            {$IFNDEF DLL}
            DispErrorDeluxe('Language File Error : ' + ScrnLang, ErrorMessage(InitStatus), TRUE, Iam);
            {$ENDIF}
            EXIT;
        END;

        {if screen and print language is the same then just point to}
        {same object}
        IF (ScrnLang = PrnLang) OR (PrnLang = '') THEN BEGIN
            PP := SP;
            MsgMgrInitDbg := TRUE;
            EXIT;
        END;
        MsgRefresh(PrnLang);
        {load printer language}
        NEW(PP, Init(PrnLang, 100, LANGREV));
        IF PP = NIL THEN BEGIN
            {$IFNDEF DLL}
            DispErrorDeluxe('Language File Error : ' + PrnLang, ErrorMessage(InitStatus), TRUE, Iam);
            {$ENDIF}
            EXIT;
        END;

        MsgMgrInitDbg := TRUE;
    END;

    {------------}

    {This function translates Strg, found in any available MSX file into the}
    {current language.                                                      }
    {Where:                                                                 }
    {Strg   = Msg to translate                                              }
    {MinMsg = lower range of possible message numbers to search             }
    {MaxMsg = upper range of possible message numbers to search             }
    {CLP    = pointer to current language object                            }
    {                                                                       }
    {If the message is not found or is a match with the current language    }
    {then TranslateToCurLang returns the original string.                   }
    {                                                                       }
    FUNCTION TranslateToCurLang(Strg           : STRING; {string to translate}
                                MinMsg, {search start in CLP}
                                MaxMsg         : WORD; {search end in CLP}
                                CLP            : MsgObjP {screen or printer}
                                )              : STRING; {either same as strg or translation}
    VAR
        SR             : SearchRec;
        I,
        J              : WORD;
        P              : MsgObjP;
        MyPath         : PathStr;

        {search range of messages for exact string match}
        FUNCTION SearchStrg(Msg            : STRING;
                            MP             : MsgObjP;
                            VAR MsgNum     : WORD) : BOOLEAN;
        VAR
            MN             : WORD;
        BEGIN
            SearchStrg := FALSE;
            FOR MN := MinMsg TO MaxMsg DO
                IF Strg = MP^.SysMsg(MN) THEN BEGIN
                    SearchStrg := TRUE;
                    MsgNum := MN;
                    EXIT;
                END;
        END;
    BEGIN
        TranslateToCurLang := Strg;

        IF CLP = NIL THEN
            EXIT;

        {look for string in current language}
        IF SearchStrg(Strg, CLP, I) THEN
            EXIT;                 {no need to translate}

        MyPath := AddBackSlash(JustPathName(PARAMSTR(0)));
        FINDFIRST(MyPath + '*.MSX', AnyFile, SR);
        WHILE DOSERROR = 0 DO BEGIN
            IF JustName(SR.Name) <> CLP^.GetCurLang THEN BEGIN
                {open this lang file}
                NEW(P, Init(SR.Name, 100, LANGREV));
                IF P = NIL THEN
                    EXIT;

                {search for string in this lang file}
                IF SearchStrg(Strg, P, I) THEN BEGIN
                    {found string, so return same index in current lang}
                    TranslateToCurLang := CLP^.SysMsg(I);
                    {clean up heap}
                    DISPOSE(P, Done);
                    EXIT;
                END;
                {clean up heap}
                DISPOSE(P, Done);
            END;
            {move to next language file}
            FindNext(SR);
        END;
    END;

    {------------}

    {change the current screen and pring language}
    FUNCTION ChangeLang(ScrnLang, PrnLang : PathStr; VAR SP, PP : MsgObjP) : BOOLEAN;
    BEGIN
        IF SP <> NIL THEN
            DISPOSE(SP, Done);

        IF (SP <> PP) AND (PP <> NIL) THEN
            DISPOSE(PP, Done);

        SP := NIL;
        PP := NIL;

        ChangeLang := MsgMgrInit(ScrnLang, PrnLang, SP, PP);
    END;

    {------------}


    CONSTRUCTOR KMenuT.Init(X1, Y1, X2, Y2 : BYTE;
                            Orient         : mnOrientation);
    BEGIN
        IF NOT INHERITED Init(X1, Y1, X2, Y2, Orient) THEN
            FAIL;
        MaxHelpLen := 0;

    END;

    {------------}

    CONSTRUCTOR KMenuT.InitCustom(X1, Y1, X2, Y2 : BYTE;
                                  VAR Colors     : ColorSet;
                                  Options        : LONGINT;
                                  Orient         : mnOrientation);
    BEGIN
        IF NOT INHERITED InitCustom(X1, Y1, X2, Y2,
                                    Colors,
                                    Options,
                                    Orient) THEN
            FAIL;
        MaxHelpLen := 0;
    END;

    {------------}

    {-Add item to current item list, allocating string space on heap}
    PROCEDURE KMenuT.KAddItem(Name           : LONGINT;
                              DisplayPos     : BYTE;
                              Key            : LONGINT);
    VAR
        Strg           : STRING;
        SelPos         : BYTE;
    BEGIN
        Strg := ScnMsgP^.SysMsg(Name);
        SelPos := GetSelectPos(Strg);
        AddItem(Strg, DisplayPos, SelPos, Key);
    END;

    {------------}

    FUNCTION KMenuT.GetMaxHelpLen : BYTE;
    BEGIN
        GetMaxHelpLen := MaxHelpLen;
    END;

    {------------}

    {-Add item to current item list, not allocating string space on heap}
    PROCEDURE KMenuT.KAddItemPtr(Name           : LONGINT;
                                 DisplayPos     : BYTE;
                                 Key            : LONGINT);
    VAR
        Strg           : STRING;
        SelPos         : BYTE;
    BEGIN
        Strg := ScnMsgP^.SysMsg(Name);
        SelPos := GetSelectPos(Strg);
        AddItemPtr(Strg, DisplayPos, SelPos, Key);
    END;

    {------------}

    {-Add item to current item list, allocating string space on heap}
    PROCEDURE KMenuT.KAddItemHelp(Name           : LONGINT;
                                  DisplayPos     : BYTE;
                                  Key            : LONGINT;
                                  Help           : LONGINT);
    VAR
        Strg,
        HStrg          : STRING;
        SelPos         : BYTE;
    BEGIN
        Strg := ScnMsgP^.SysMsg(Name);
        HStrg := ScnMsgP^.SysMsg(Help);
        MaxHelpLen := MaxLong(LENGTH(HStrg), MaxHelpLen);
        SelPos := GetSelectPos(Strg);
        AddItemHelp(Strg, DisplayPos, SelPos, Key, HStrg);
    END;

    {------------}

    PROCEDURE KMenuT.KAddItemHelpPtr(Name           : LONGINT;
                                     DisplayPos     : BYTE;
                                     Key            : LONGINT;
                                     Help           : LONGINT);

    VAR
        Strg,
        HStrg          : STRING;
        SelPos         : BYTE;
    BEGIN
        Strg := ScnMsgP^.SysMsg(Name);
        HStrg := ScnMsgP^.SysMsg(Help);
        MaxHelpLen := MaxLong(LENGTH(HStrg), MaxHelpLen);
        SelPos := GetSelectPos(Strg);
        AddItemHelpPtr(Strg, DisplayPos, SelPos, Key, HStrg);
    END;

    {------------}

    FUNCTION KMenuT.GetSelectPos(VAR Strg : STRING) : BYTE;
    VAR
        CPos           : BYTE;
    BEGIN
        CPos := POS('&', Strg);
        IF CPos <> 0 THEN
            Strg := Filter(Strg, ['&']);
        GetSelectPos := CPos;
    END;

    {------------}

    {look up the language specific hotkey}
    FUNCTION LookupCommand(N : LONGINT; VAR SP : MsgObjP) : WORD;
    VAR
        L              : LONGINT;
    BEGIN
        IF NOT Str2Long(ExtractWord(2, SP^.SysMsg(N), ['=']), L) THEN
            RingBell;
        LookupCommand := L;
    END;

    {------------}

TYPE
    CSMask         = ARRAY[0..31] OF BYTE;

    {init the opro Yes,No,True,False keysets and characters for a given }
    {language                                                           }
    {This overwrites the Opro charsets in memory                        }
    PROCEDURE InitYNTF(Y, N, T, F : LONGINT);
    VAR
        BS             : CSMask ABSOLUTE BOOLEANSET;
        YS             : CSMask ABSOLUTE YESNOSET;
        FUNCTION GetCharVal(L : LONGINT) : CHAR;
        VAR
            Strg           : STRING;
        BEGIN
            Strg := Trim(ExtractWord(2, ScnMsgP^.SysMsg(L), ['=']));
            IF LENGTH(Strg) <> 1 THEN
                RingBell;
            GetCharVal := Strg[1];
        END;
        PROCEDURE OverWriteSet(VAR S : CSMask; C : CHAR);
        BEGIN
            {charsets are stored as 32 bytes (256 bits) of bitwise flags }
            {each bit represents a single char in the ASCII charset      }

            {calc the character position and set the appropriate flag true}
            S[ORD(C) DIV 8] := S[ORD(C) DIV 8] OR (1 SHL (ORD(C) MOD 8));
        END;
    BEGIN
        {start with a clean slate}
        FILLCHAR(BS, SIZEOF(CSMask), #0);
        FILLCHAR(YS, SIZEOF(CSMask), #0);

        {Get the Y/N chars for this language}
        YesChar := GetCharVal(Y);
        NoChar := GetCharVal(N);

        {overwrite the YesNo charset}
        OverWriteSet(YS, LoCase(YesChar));
        OverWriteSet(YS, UPCASE(YesChar));
        OverWriteSet(YS, LoCase(NoChar));
        OverWriteSet(YS, UPCASE(NoChar));

        {Get the TF chars for this language}
        TrueChar := GetCharVal(T);
        FalseChar := GetCharVal(F);

        {overwrite the TrueFalse charset}
        OverWriteSet(BS, UPCASE(TrueChar));
        OverWriteSet(BS, LoCase(TrueChar));
        OverWriteSet(BS, UPCASE(FalseChar));
        OverWriteSet(BS, LoCase(FalseChar));
    END;

    {--------------------}

    PROCEDURE InitYNTF2(Y, N, T, F, MYes, MNo, MTrue, MFalse : LONGINT);
    BEGIN
        InitYNTF(Y, N, T, F);
        IF ScnMsgP <> NIL THEN BEGIN
            StrYes := ScnMsgP^.SysMsg(MYes) {YES} ;
            StrNo := ScnMsgP^.SysMsg(MNo) {NO} ;
            StrTrue := ScnMsgP^.SysMsg(MTrue) {TRUE} ;
            StrFalse := ScnMsgP^.SysMsg(MFalse) {FALSE} ;
        END;
    END;

    {--------------------}
    {$IFNDEF DLL}
BEGIN
    StrYes := 'YES';
    StrNo := 'NO';
    StrTrue := 'TRUE';
    StrFalse := 'FALSE';
    {$ENDIF}
END.
    {------------}
    {------------}
