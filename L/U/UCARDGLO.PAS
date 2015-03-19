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
Const
  NumKeywords  = 20;
  TotalKeys    = 27;   { 20 keywords + 7 others }
  FirstKeyword = 8;
  CardListSize = 100;  { Size of final selection menu }

Type
  KeyWordSt  = String[15];
  KeyArray   = Array[1..NumKeywords] of KeywordSt;

  AnyString  = String[80];

  MemoBuffer = Array[1..512] of Char;

  Searches   = (Strict,Relaxed,Loose);

  Card_Index = Record       { Data record format in Database }
      Rebuild  : LongInt;       { 4-byte Delete/Rebuild area for Filer }
      CardID   : String[8];     { 4 byte julian date + 4 byte time creation time }
      UserID   : String[20];    { User that added this card }
      Name     : String[30];    { next 7 fields are scanned for keywords, & }
      Company  : String[30];    { indexed to a max of 20 words }
      Title    : String[30];
      Address  : String[30];
      City     : String[20];    { Indexed with spaces stripped }
      State    : String[20];    { Indexed with spaces stripped }
      StateCode: String[2];     { 2 character postal abbreviation }
      Country  : String[20];    { Indexed with spaces stripped }
      Zip      : String[10];    { Indexed }
      Areacode : String[3];
      Phone    : String[20];    { Area code & Phone indexed separately }
      AltPhone : String[20];
      Remote   : String[20];    { Name of service, if remote }
      Keywords : Array[1..NumKeywords] of KeywordSt;
      Memo     : MemoBuffer;   { Text buffer }
    end;
    CardIndexPtr = ^Card_Index;

  Card_Search = Record     { Search mask format }
      Keywords : Array[1..5] of KeywordSt;
      City     : String[20];
      State    : String[20];
      Country  : String[20];
      Zip      : String[10];
      AreaCode : String[3];
      Phone    : String[20];
    end;
    CardSearchPtr = ^Card_Search;

  CardListType = Array[1..CardListSize] of BigString;
  CardListPtr  = ^CardListType;

  AutoDialRecord = record
    ComPort  : integer;    { Com port modem is attached to }
    Baud     : integer;    { Baud rate (Default 1200) }
    Parity   : char;       { Parity E,O,N (Default N) }
    DataBits : byte;       { Data bits (Default 8) }
    StopBits : byte;       { Stop bits (Default 1) }
    ToneDial : boolean;    { Tone or Pulse dial (Default Tone) }
    Access   : word;       { Access code for outside line (Default 0=none) }
    LocalArea: String[3];  { Local area code }
    Emulation: word;       { terminal emulation type }
    end;

  AreaCodeArray = Array[1..500] of BigString; { Dummy, actual len will vary }

Var
  CardData      :  CardIndexPtr;
  SearchMask    :  CardSearchPtr;
  CardIndex     :  ^DBtree;
  CardPath      :  pathStr;

Const

  KeyLength : Array[1..TotalKeys] of byte =    { Unpacked size }
    (8,20,20,20,10,5,20,
     15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15);

  CardIndexOpen :  boolean = False;

Var
  OldCardData     :  CardIndexPtr;
  ESRSearch       :  EntryScreenPtr;
  ESRCard         :  EntryScreenPtr;
  EMCB            :  NENEditorPtr;      { EditMemo control block }
  Done            :  boolean;
  Back,Frame      :  byte;
  FieldsRequested :  integer;
  Found           :  word;
  Choice          :  integer;
  SearchMode      :  Searches;
  CardList        :  ^CardListType;
  DeleteFlag      :  boolean;
  AutoDial        :  AutoDialRecord;
  Match           :  Char;

  Const
    SelectHeading =
     '  '+#$A9+'  Name                            Phone              '+#$AA;
    GetCardHeading =
     #$A9+'Time Slug                            Type Date       '+#$AA;
    PrintSelectHeading =
         '  Card Time Slug                           Date   ';
    PrintGetCardHeading =
         'Time Slug                            Type Date   ';

    Locked   = True;
    Unlocked = False;

    PgUpPgDn : boolean = True;

    Zero : LongInt = 0;

var
  AreaCodes    : ^AreaCodeArray;
  AreaCodeSize :  Word;
  TotalAreaCodes: Word;
  IID          : IsamIndDescr;
  DosExit      : boolean;

