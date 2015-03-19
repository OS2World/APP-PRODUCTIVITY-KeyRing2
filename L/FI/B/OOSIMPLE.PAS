program OoSimple;
  {-Simple example of using OOFILER}
uses
  FILER, OOFILER;
type
  PersonDef =
    record
      Del : LongInt;
      FirstName : String[20];
      LastName : String[25];
      Street : String[30];
      City : String[30];
      State : String[2];
      ZipCode : String[9];
      Telephone : String[15];
      Age : Integer;
    end;
  PersonFile =
    object(Fileblock)
      CurRef : LongInt;
      CurRec : PersonDef;
      constructor Init(FName : IsamFileBlockName; SaveMode : Boolean);

      {---- required implementations of abstract methods ----}
      function BuildKey(var Rec; KeyNr : Word) : IsamKeyStr; virtual;
      function EqualRec(var Rec1, Rec2) : Boolean; virtual;

      {---- optional overrides for virtual methods ----}
      procedure HardError; virtual;
    end;
const
  APerson : PersonDef =
  (Del : 0;
   FirstName : 'George';
   LastName : 'Bush';
   Street : '1600 Penn. Ave';
   City : 'Washington';
   State : 'DC';
   ZipCode : '10011-0001';
   Telephone : '301-222-1111';
   Age : 64);
var
  PS : LongInt;
  F : PersonFile;

constructor PersonFile.Init(FName : IsamFileBlockName; SaveMode : Boolean);
var
  NetMode : Boolean;
  IID : IsamIndDescr;

  procedure InitIID;
  begin
    IID[1].KeyL := 30;
    IID[1].AllowDupK := False;
    IID[2].KeyL := 5;
    IID[2].AllowDupK := True;
    IID[3].KeyL := 15;
    IID[3].AllowDupK := True;
  end;

begin
  {Assume network fileblock if the FILER unit was initialized for a network}
  NetMode := (BTNetSupported <> NoNet);

  {Initialize data fields new to a PersonFile}
  CurRef := 0;

  if Fileblock.Init(FName, False, False, SaveMode, NetMode) then
    {Opened existing file}
    Exit;

  case IsamError of
     9903 : {Data file not found}
       begin
         InitIID;
         if Fileblock.Create(FName, SizeOf(PersonDef), 3, IID,
                             False, False, SaveMode, NetMode) then
           Exit;
       end;
    10010 : {Fileblock corrupt}
      begin
        InitIID;
        if Fileblock.Recover(FName, SizeOf(PersonDef), 3, IID, True,
                             False, False, SaveMode, NetMode) then
          Exit;
      end;
  else
    {Unexpected error. Recover might still succeed}
    Fail;
  end;

  {Couldn't open, create, or rebuild fileblock if we get here}
  Fail;
end;

function StUpcase(S : String) : String;
var
  I : Integer;
begin
  for I := 1 to Length(S) do
    S[I] := Upcase(S[I]);
  StUpcase := S;
end;

function Pad(S : String; Len : Byte) : String;
var
  SLen : Byte absolute S;
begin
  if SLen > Len then
    SLen := Len
  else
    while SLen < Len do
      S := S+' ';
  Pad := S;
end;

function PersonFile.BuildKey(var Rec; KeyNr : Word) : IsamKeyStr;
begin
  with PersonDef(Rec) do
    case KeyNr of
      1 : BuildKey := StUpcase(Pad(LastName, 20)+Pad(FirstName, 10));
      2 : BuildKey := Copy(ZipCode, 1, 5);
      3 : BuildKey := Copy(Telephone, 1, 15);
    else
      BuildKey := '';
    end;
end;

function PersonFile.EqualRec(var Rec1, Rec2) : Boolean;
var
  P1 : PersonDef absolute Rec1;
  P2 : PersonDef absolute Rec2;
begin
  EqualRec := False;
  if P1.Del <> P2.Del then
    Exit;
  if P1.FirstName <> P2.FirstName then
    Exit;
  if P1.LastName <> P2.LastName then
    Exit;
  if P1.Street <> P2.Street then
    Exit;
  if P1.City <> P2.City then
    Exit;
  if P1.State <> P2.State then
    Exit;
  if P1.ZipCode <> P2.ZipCode then
    Exit;
  if P1.Telephone <> P2.Telephone then
    Exit;
  if P1.Age <> P2.Age then
    Exit;
  EqualRec := True;
end;

procedure ReportError;
begin
  Writeln('Isam error ', IsamError);
end;

procedure PersonFile.HardError;
begin
  ReportError;
  Done;
  BTExitIsam;
  Halt;
end;

procedure CheckOK;
begin
  if not IsamOK then begin
    ReportError;
    Halt;
  end;
end;

begin
  {Initialize Filer unit}
  PS := BTInitIsam(NoNet, MinimizeUseOfNormalHeap, 0);
  CheckOK;

  {Open fileblock}
  if not F.Init('TEST', False) then
    CheckOK;

  {See if any records}
  if F.UsedRecs >= 0 then
    {Add a record}
    F.AddRecord(F.CurRef, APerson);

  {Search for a record}
  F.FindKey(2, F.CurRef, '10011');
  if not IsamOk then
    Writeln('key not found')
  else begin
    {Read the record}
    F.GetRec(F.CurRef, F.CurRec);
    {Do something with the record}
    {...}
    {Delete the record}
    F.DeleteRecord(F.CurRef, F.CurRec);
  end;

  {Close fileblock}
  F.Done;

  {Deinstall FILER unit}
  BTExitIsam;
end.
