{$S-,R-,V-,I-,B-,F+,O+,A-}
{$M 16384,10000,655360}

program Relate;
  {-Demonstrate a simple relational database}

  {*************************************************************************
  Features:
    - shows solution to the common Customer/Order/Item database scenario
    - three fileblocks open in one program
    - fileblocks are linked by shared key
    - use of unkeyed records to get unique customer and order number
    - use of NUMKEYS to convert longint's to key strings
    - everything survives a rebuild
  **************************************************************************}

uses
  FILER, OOFILER, NUMKEYS;

type
  CustomerDef =
    record
      Dele : LongInt;
      CustNum : LongInt;                       {1. Primary key for customers}
      CustStatus : (CCounter, Active, Inactive);
      Company : String[30];                    {2. Secondary key}
      Zip : String[10];                        {3. Secondary key}
    end;

  OrderDef =
    record
      Dele : LongInt;
      CustNum : LongInt;                       {1. Secondary key}
      OrderNum : LongInt;                      {2. Primary key for orders}
      OrderStatus : (OCounter, Pending, OnHold, Shipped);
      DatePlaced : String[8];
      AmountDue : LongInt;                     {In pennies}
    end;

  ItemDef =
    record                                     {No primary key}
      Dele : LongInt;
      OrderNum : LongInt;                      {1. Secondary key}
      ItemName : String[30];                   {2. Secondary key}
      ItemPrice : LongInt;                     {In pennies}
      Quantity : LongInt;
    end;

  {This set of relations could easily be extended. For example, there could be
   an ItemDescription file. Each ItemDef record would contain an ItemNum field
   rather than ItemName and ItemPrice. ItemNum would also be an index into the
   ItemDescription file, each record of which would contain the unit price of
   the item, its name, a description, inventory level, etc.}

  CustomerFilePtr = ^CustomerFile;
  OrderFilePtr = ^OrderFile;
  ItemFilePtr = ^ItemFile;

  CustomerFile =
    object(Fileblock)
      CurRef : LongInt;
      CurRec : CustomerDef;

      function BuildKey(var Rec; KeyNr : Word) : IsamKeyStr; virtual;
        {-Return key string for given record and index number}
      function EqualRec(var Rec1, Rec2) : Boolean; virtual;
        {-Return True if two records are considered to be the same}

      procedure AddNewCustomer;
        {-Assign unique CustNum, set CustStatus and Dele, and add record}
      procedure ShowCustomers;
        {-Show all customers}
    end;

  OrderFile =
    object(Fileblock)
      CurRef : LongInt;
      CurRec : OrderDef;

      function BuildKey(var Rec; KeyNr : Word) : IsamKeyStr; virtual;
        {-Return key string for given record and index number}
      function EqualRec(var Rec1, Rec2) : Boolean; virtual;
        {-Return True if two records are considered to be the same}

      procedure AddNewOrder;
        {-Assign unique OrderNum, set OrderStatus and Dele, and add record}
      procedure ShowOrders(CNum : LongInt; IFileP : ItemFilePtr);
        {-Show all orders for customer CNum, including items from IFileP^}
    end;

  ItemFile =
    object(Fileblock)
      CurRef : LongInt;
      CurRec : ItemDef;

      function BuildKey(var Rec; KeyNr : Word) : IsamKeyStr; virtual;
        {-Return key string for given record and index number}
      function EqualRec(var Rec1, Rec2) : Boolean; virtual;
        {-Return True if two records are considered to be the same}

      procedure ShowItems(ONum : LongInt);
        {-Show all items in given order number}
    end;

const
  CName = 'CUSTXXX';   {Name for customer fileblock}
  OName = 'ORDRXXX';   {Name for order fileblock}
  IName = 'ITEMXXX';   {Name for item fileblock}

var
  CFile : CustomerFile;
  OFile : OrderFile;
  IFile : ItemFile;

  {----------------------------------------------------------------------}

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

function DollarStr(Pennies : LongInt) : String;
var
  S : String;
begin
  Str(Pennies, S);
  while Length(S) < 2 do
    S := '0'+S;
  Insert('.', S, Length(S)-1);
  while Length(S) < 4 do
    S := '0'+S;
  DollarStr := '$'+S;
end;

  {----------------------------------------------------------------------}

function CustomerFile.BuildKey(var Rec; KeyNr : Word) : IsamKeyStr;
begin
  with CustomerDef(Rec) do
    if CustStatus = CCounter then
      {Counter customer is a special unkeyed record}
      {Null keys are not added for this Fileblock}
      BuildKey := ''
    else
      case KeyNr of
        1 : BuildKey := LongToKey(CustNum);
        2 : BuildKey := StUpcase(Company);
        3 : BuildKey := StUpcase(Zip);
      end;
end;

function CustomerFile.EqualRec(var Rec1, Rec2) : Boolean;
var
  R1 : CustomerDef absolute Rec1;
  R2 : CustomerDef absolute Rec2;
begin
  EqualRec := False;
  if R1.Dele <> R2.Dele then
    Exit;
  if R1.CustNum <> R2.CustNum then
    Exit;
  if R1.CustStatus <> R2.CustStatus then
    Exit;
  if R1.Company <> R2.Company then
    Exit;
  if R1.Zip <> R2.Zip then
    Exit;
  EqualRec := True;
end;

procedure CustomerFile.AddNewCustomer;
label
  ExitPoint;
var
  NewCustNum : LongInt;
  SysRec : CustomerDef;
begin
  if not AssureFileblockOpen then
    Exit;

  {Get the next available customer number}
  Lock;
  if not IsamOk then
    Exit;
  GetRec(1, SysRec);
  if not IsamOK then
    goto ExitPoint;
  NewCustNum := SysRec.CustNum+1;
  SysRec.CustNum := NewCustNum;
  PutRec(1, SysRec);
  if not IsamOK then
    goto ExitPoint;

  {Add the new customer}
  CurRec.CustNum := NewCustNum;
  CurRec.CustStatus := Active;
  CurRec.Dele := 0;
  AddRecord(CurRef, CurRec);

ExitPoint:
  Unlock;
end;

procedure CustomerFile.ShowCustomers;
var
  KeyStr : IsamKeyStr;
begin
  WriteLn('CustNum   Company Name                    Zip');
  WriteLn('-------   ------------------------------  ----------');

  ClearKey(1);
  while IsamOK do begin
    NextKey(1, CurRef, KeyStr);
    if IsamOK then begin
      GetRec(CurRef, CurRec);
      if IsamOK then
        Writeln('  ', CurRec.CustNum:4, '.   ',
                Pad(CurRec.Company, 30), '  ', CurRec.Zip);
    end;
  end;
end;

  {----------------------------------------------------------------------}

function OrderFile.BuildKey(var Rec; KeyNr : Word) : IsamKeyStr;
begin
  with OrderDef(Rec) do
    if OrderStatus = OCounter then
      {Counter order is a special unkeyed record}
      BuildKey := ''
    else
      case KeyNr of
        1 : BuildKey := LongToKey(CustNum);
        2 : BuildKey := LongToKey(OrderNum);
      end;
end;

function OrderFile.EqualRec(var Rec1, Rec2) : Boolean;
var
  R1 : OrderDef absolute Rec1;
  R2 : OrderDef absolute Rec2;
begin
  EqualRec := False;
  if R1.Dele <> R2.Dele then
    Exit;
  if R1.CustNum <> R2.CustNum then
    Exit;
  if R1.OrderNum <> R2.OrderNum then
    Exit;
  if R1.OrderStatus <> R2.OrderStatus then
    Exit;
  if R1.DatePlaced <> R2.DatePlaced then
    Exit;
  if R1.AmountDue <> R2.AmountDue then
    Exit;
  EqualRec := True;
end;

procedure OrderFile.AddNewOrder;
label
  ExitPoint;
var
  NewOrderNum : LongInt;
  SysRec : OrderDef;
begin
  if not AssureFileblockOpen then
    Exit;

  {Get the next available order number}
  Lock;
  if not IsamOk then
    Exit;
  GetRec(1, SysRec);
  if not IsamOK then
    goto ExitPoint;
  NewOrderNum := SysRec.OrderNum+1;
  SysRec.OrderNum := NewOrderNum;
  PutRec(1, SysRec);
  if not IsamOK then
    goto ExitPoint;

  {Add the new order}
  CurRec.OrderNum := NewOrderNum;
  CurRec.OrderStatus := Pending;
  CurRec.Dele := 0;
  AddRecord(CurRef, CurRec);

ExitPoint:
  Unlock;
end;

procedure OrderFile.ShowOrders(CNum : LongInt; IFileP : ItemFilePtr);
label
  ExitPoint;
var
  Matched : Boolean;
  KeyStr : IsamKeyStr;
  NewStr : IsamKeyStr;
begin
  WriteLn(' Order      Date      Amount   Detail');
  WriteLn('-------   --------  --------  -------------------------');

  {Don't let anyone change the order file while we write the list}
  ReadLock;
  if not IsamOK then
    Exit;

  {Find the first order for this customer}
  KeyStr := LongToKey(CNum);
  FindKey(1, CurRef, KeyStr);
  if not IsamOk then begin
    WriteLn('  none');
    goto ExitPoint;
  end;

  {Scan all the orders for this customer}
  Matched := True;
  while IsamOk and Matched do begin
    GetRec(CurRef, CurRec);
    if not IsamOK then
      goto ExitPoint;

    {Write summary of order}
    WriteLn('  ', CurRec.OrderNum:5, '   ',
            CurRec.DatePlaced, '  ',
            DollarStr(CurRec.AmountDue):8);

    {Write detail list of items ordered}
    IFileP^.ShowItems(CurRec.OrderNum);

    {Move to next record in customer order}
    NextKey(1, CurRef, NewStr);
    if IsamOK then
      Matched := (NewStr = KeyStr);
  end;

ExitPoint:
  Unlock;
end;

  {----------------------------------------------------------------------}

function ItemFile.BuildKey(var Rec; KeyNr : Word) : IsamKeyStr;
begin
  with ItemDef(Rec) do
    case KeyNr of
      1 : BuildKey := LongToKey(OrderNum);
      2 : BuildKey := StUpcase(ItemName);
    end;
end;

function ItemFile.EqualRec(var Rec1, Rec2) : Boolean;
var
  R1 : ItemDef absolute Rec1;
  R2 : ItemDef absolute Rec2;
begin
  EqualRec := False;
  if R1.Dele <> R2.Dele then
    Exit;
  if R1.OrderNum <> R2.OrderNum then
    Exit;
  if R1.ItemName <> R2.ItemName then
    Exit;
  if R1.ItemPrice <> R2.ItemPrice then
    Exit;
  if R1.Quantity <> R2.Quantity then
    Exit;
  EqualRec := True;
end;

procedure ItemFile.ShowItems(ONum : LongInt);
label
  ExitPoint;
const
  Indent = 28;
var
  Matched : Boolean;
  KeyStr : IsamKeyStr;
  NewStr : IsamKeyStr;
begin
  {Don't let anyone change the item file while we write the list}
  ReadLock;
  if not IsamOK then
    Exit;

  {Find the first item for this order}
  KeyStr := LongToKey(ONum);
  FindKey(1, CurRef, KeyStr);
  if not IsamOk then begin
    WriteLn('  none');
    goto ExitPoint;
  end;

  {Scan all the items for this order}
  Matched := True;
  while IsamOk and Matched do begin
    GetRec(CurRef, CurRec);
    if not IsamOK then
      goto ExitPoint;

    {Write summary of order}
    WriteLn('':Indent, CurRec.Quantity:4, ' @ ',
            DollarStr(CurRec.ItemPrice):8, '  ',
            CurRec.ItemName);

    {Move to next record in order order}
    NextKey(1, CurRef, NewStr);
    if IsamOK then
      Matched := (NewStr = KeyStr);
  end;

ExitPoint:
  Unlock;
end;

  {----------------------------------------------------------------------}

procedure HaltOnIsamError;
  {-If IsamOK is False, write the error number and halt the application}
begin
  if not IsamOK then begin
    Writeln('Isam error ', IsamError);
    Halt;
  end;
end;

procedure AddDummyData;
  {-Add dummy customers, orders, items for demonstration}
const
  CustCnt = 5;
  CustNames : array[1..CustCnt] of string[30] =
    ('TurboPower', 'Borland', 'Microsoft', 'Lotus', 'WordPerfect');
  CustZips : array[1..CustCnt] of string[10] =
    ('95066', '95066', '98073', '06412', '81254');
  OrderCnt = 15;
  OrderDates : array[1..OrderCnt] of string[8] =
    ('90/12/22', '90/12/31', '91/01/13', '91/01/22', '91/02/01',
     '91/02/09', '91/02/10', '91/02/12', '91/02/18', '91/02/22',
     '91/03/03', '91/03/04', '91/03/14', '91/03/20', '91/03/28');
  ItemCnt = 15;
  ItemNames : array[1..ItemCnt] of string[30] =
    ('Diskettes, 3.5"', 'Diskettes, 5.25"',
     'Tyvek sleeves', 'Shipping boxes, 9x7x3',
     'Shipping boxes, 8x5x2', 'Strapping tape',
     'Postage meter labels, 500', 'Shipping forms',
     'Registration cards', 'Bubble pack sheets, 1000',
     'Mailing labels, 500', 'Gummy labels, 5000',
     'Marking pen', 'Airmail stamper',
     'Stapler');
  ItemPrices : array[1..ItemCnt] of LongInt =
    (65, 29, 05, 45, 35, 99, 199, 02, 02, 595, 199, 1099, 155, 995, 1495);
var
  C : Word;
  O : Word;
  I : Word;
begin
  for C := 1 to CustCnt do begin
    {Add each new customer}
    with CFile.CurRec do begin
      Company := CustNames[C];
      Zip := CustZips[C];
    end;
    CFile.AddNewCustomer;
    HaltOnIsamError;

    {Add some orders for the customer}
    for O := 1 to OrderCnt do
      {Take every eighth order date on the average}
      if Random(8) = 1 then begin
        {Add a new order}
        with OFile.CurRec do begin
          CustNum := CFile.CurRec.CustNum; {Same customer we just added}
          DatePlaced := OrderDates[O];
          AmountDue := 0;
        end;
        OFile.AddNewOrder;
        HaltOnIsamError;

        {Add some items for this order}
        for I := 1 to ItemCnt do
          {Take every eighth item on the average, but assure one at least}
          if (Random(8) = 1) or
             ((I = ItemCnt) and (OFile.CurRec.AmountDue = 0)) then begin
            {Initialize and add an item}
            with IFile.CurRec do begin
              Dele := 0;
              OrderNum := OFile.CurRec.OrderNum; {Same order we just added}
              ItemName := ItemNames[I];
              ItemPrice := ItemPrices[I];
              Quantity := Random(10)+1;
              inc(OFile.CurRec.AmountDue, Quantity*ItemPrice);
            end;
            IFile.AddRecord(IFile.CurRef, IFile.CurRec);
            HaltOnIsamError;
          end;

        {Update the price due for the order}
        OFile.PutRec(OFile.CurRef, OFile.CurRec);
        HaltOnIsamError;
      end;
  end;
end;

procedure CreateFiles;
  {-Create and open Customer, Order, and Item files}

  procedure CreateCFile;
  var
    IID : IsamIndDescr;
  begin
    IID[1].KeyL := 4;            {Key 1 is LongToKey(CustNum)}
    IID[1].AllowDupK := False;   {Primary}
    IID[2].KeyL := 30;           {Key 2 is StUpcase(Company)}
    IID[2].AllowDupK := True;    {Secondary}
    IID[3].KeyL := 10;           {Key 3 is StUpcase(Zip)}
    IID[3].AllowDupK := True;    {Secondary}

    {Create the fileblock}
    if not CFile.Create(CName, SizeOf(CustomerDef),
                        3, IID,
                        False, False, False, False) then HaltOnIsamError;

    {Don't add null keys}
    CFile.NullKeys(False);

    {Add counter record used to assign unique customer numbers}
    FillChar(CFile.CurRec, SizeOf(CustomerDef), 0);
    CFile.CurRec.CustStatus := CCounter;
    CFile.CurRec.CustNum := 0;  {Starting customer-1}
    CFile.AddRecord(CFile.CurRef, CFile.CurRec);
  end;

  procedure CreateOFile;
  var
    IID : IsamIndDescr;
  begin
    IID[1].KeyL := 4;            {Key 1 is LongToKey(CustNum)}
    IID[1].AllowDupK := True;    {Secondary}
    IID[2].KeyL := 4;            {Key 2 is LongToKey(OrderNum)}
    IID[2].AllowDupK := False;   {Primary}

    if not OFile.Create(OName, SizeOf(OrderDef),
                        2, IID,
                        False, False, False, False) then HaltOnIsamError;

    {Don't add null keys}
    OFile.NullKeys(False);

    {Add counter record used to assign unique order numbers}
    FillChar(OFile.CurRec, SizeOf(OrderDef), 0);
    OFile.CurRec.OrderStatus := OCounter;
    OFile.CurRec.OrderNum := 50000;  {Starting order-1}
    OFile.AddRecord(OFile.CurRef, OFile.CurRec);
  end;

  procedure CreateIFile;
  var
    IID : IsamIndDescr;
  begin
    IID[1].KeyL := 4;            {Key 1 is LongToKey(OrderNum)}
    IID[1].AllowDupK := True;    {Secondary}
    IID[2].KeyL := 30;           {Key 2 is StUpcase(ItemName)}
    IID[2].AllowDupK := True;    {Secondary}

    if not IFile.Create(IName, SizeOf(ItemDef),
                        2, IID,
                        False, False, False, False) then HaltOnIsamError;
  end;

begin
  CreateCFile;
  CreateOFile;
  CreateIFile;
end;

procedure DisplayFiles;
  {-Interactively display information about customers}
var
  Code : Word;
  Num : LongInt;
  S : String[10];
begin
  repeat
    WriteLn;
    CFile.ShowCustomers;
    WriteLn;
    Write('Choose customer number for detail (Enter to quit): ');
    ReadLn(S);
    if Length(S) = 0 then
      Exit;
    Val(S, Num, Code);
    if Code <> 0 then
      Writeln('Invalid number, try again...')
    else if not CFile.KeyExists(1, 0, LongToKey(Num)) then
      Writeln('Not an existing customer, try again...')
    else begin
      {Dump all orders for this customer}
      WriteLn;
      OFile.ShowOrders(Num, @IFile);
      Write('Press <Enter> ');
      ReadLn;
    end;
  until False;
end;

procedure CloseFiles;
begin
  CFile.Delete;
  OFile.Delete;
  IFile.Delete;
end;

begin
  {Commenting out the following removes randomness for testing}
  Randomize;

  {Initialize Filer unit}
  if BTInitIsam(NoNet, 10000, 0) = 0 then ;
  HaltOnIsamError;

  {Create the test files}
  CreateFiles;

  {Add dummy data to the files}
  AddDummyData;

  {Interactively display information about the files}
  DisplayFiles;

  {Close and delete the test files}
  CloseFiles;

  {Deinstall FILER unit}
  BTExitIsam;
end.
