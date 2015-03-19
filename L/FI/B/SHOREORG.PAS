{$R-,S-,I-}
{$M 16384,20000,655360}

program ShoReorg;
  {-Demonstrate the Reorganize constructor of the Fileblock object}
uses
  filer,
  oofiler;

type
  oldrect =                 {record type stored in original fileblock}
    record
      dele : longint;
      string1 : string[10];
      string2 : string[10];
    end;
  newrect =                 {record type stored in reorganized fileblock}
    record
      dele : longint;
      string1 : string[10];
      string2 : string[10];
      string3 : string[10]; {added field in reorganized fileblock}
    end;

type
  oldfb =                   {object type for original fileblock}
    object(fileblock)
      function BuildKey(var Rec; KeyNr : Word) : IsamKeyStr; virtual;
      function EqualRec(var Rec1, Rec2) : Boolean; virtual;
    end;

  newfb =                   {object type for reorganized fileblock}
    object(fileblock)
      function BuildKey(var Rec; KeyNr : Word) : IsamKeyStr; virtual;
      function EqualRec(var Rec1, Rec2) : Boolean; virtual;
      {---> note: must override ConvertRec if Reorganize will be called}
      function ConvertRec(var OldRec, NewRec; var Len : Word) : Boolean; virtual;
    end;

var
  o : oldfb;
  n : newfb;

function oldfb.BuildKey(var Rec; KeyNr : Word) : IsamKeyStr;
  {-Build keys for the old fileblock}
begin
  case keynr of
    1 : buildkey := oldrect(rec).string1;
    2 : buildkey := oldrect(rec).string2;
  else
    buildkey := '';
  end;
end;

function oldfb.EqualRec(var Rec1, Rec2) : Boolean;
  {-Determine whether two records equal for old fileblock}
begin
  equalrec := (oldrect(rec1).string1 = oldrect(rec2).string1) and
              (oldrect(rec1).string2 = oldrect(rec2).string2);
end;

function newfb.BuildKey(var Rec; KeyNr : Word) : IsamKeyStr;
  {-Build keys for the new fileblock}
begin
  case keynr of
    1 : buildkey := newrect(rec).string1;
    2 : buildkey := newrect(rec).string2;
    3 : buildkey := newrect(rec).string3;
  else
    buildkey := '';
  end;
end;

function newfb.EqualRec(var Rec1, Rec2) : Boolean;
  {-Determine whether two records equal for new fileblock}
begin
  equalrec := (newrect(rec1).string1 = newrect(rec2).string1) and
              (newrect(rec1).string2 = newrect(rec2).string2) and
              (newrect(rec1).string3 = newrect(rec2).string3);
end;

function newfb.ConvertRec(var OldRec, NewRec; var Len : Word) : Boolean;
  {-Convert records from old format to new format}
begin
  if oldrect(oldrec).dele <> 0 then
    {Don't pass on deleted records}
    ConvertRec := False
  else begin
    {Copy old fields to new record}
    newrect(newrec).dele := 0;
    newrect(newrec).string1 := oldrect(oldrec).string1;
    newrect(newrec).string2 := oldrect(oldrec).string2;
    {Initialize new field of new record}
    newrect(newrec).string3 := 'new';
    {Add this record to new fileblock}
    ConvertRec := true;
  end;
end;

procedure checkok;
begin
  if not isamok then begin
    writeln('isamerror ', isamerror);
    halt;
  end;
end;

procedure makeold;
  {-Create the old fileblock and add some demo records to it}
var
  i : integer;
  ref : longint;
  orec : oldrect;
  iid : isaminddescr;
begin
  {Old fileblock has 2 indexes}
  iid[1].keyl := 10;
  iid[1].allowdupk := true;
  iid[2].keyl := 10;
  iid[2].allowdupk := true;
  if not o.create('junk', sizeof(oldrect), 2, iid,
                  false, false, false, false) then begin
    writeln('error creating old ', isamerror);
    halt;
  end;

  {Add 20 records for demonstration}
  for i := 1 to 20 do begin
    fillchar(orec, sizeof(oldrect), 0);
    {First field contains a counter}
    str(i, orec.string1);
    while length(orec.string1) < 3 do
      orec.string1 := '0'+orec.string1;
    {Second field contains a constant string}
    orec.string2 := 'old';
    o.addrecord(ref, orec);
    checkok;
  end;
  o.done;
end;

procedure reorgnew;
  {-Reorganize the old fileblock into a new one}
var
  ref : longint;
  nrec : newrect;
  keystr : isamkeystr;
  iid : isaminddescr;
begin
  {New fileblock has 3 indexes}
  iid[1].keyl := 10;
  iid[1].allowdupk := true;
  iid[2].keyl := 10;
  iid[2].allowdupk := true;
  iid[3].keyl := 10;
  iid[3].allowdupk := true;

  {Reorganize and open it}
  if not n.reorganize('junk',                           {file name}
                      sizeof(oldrect), sizeof(newrect), {record lengths}
                      3, iid,                           {indexes}
                      false,                            {add null}
                      false, false, false, false)       {open mode}
  then begin
    writeln('error reorganizing new ', isamerror);
    halt;
  end;

  {Scan the records in key order on index 1}
  n.clearkey(1);
  while isamok do begin
    n.nextkey(1, ref, keystr);
    if isamok then begin
      n.getrec(ref, nrec);
      if isamok then
        writeln(nrec.string1:4, ' ', nrec.string2, ' ', nrec.string3);
    end;
  end;

  {Delete the demo fileblock}
  n.delete;
end;

begin
  if BTInitIsam(NoNet, MinimizeUseOfNormalHeap, 0) = 0 then halt;
  makeold;
  reorgnew;
  BTExitIsam;
end.
