{$R-,S-,I-}
{$M 16384,20000,655360}

program ShVReorg;
  {-Demonstrate the Reorganize constructor of the VFileblock object}
uses
  filer,
  vrec,
  oofiler,
  oovrec;

const
  sectlen = 35;

type
  oldrect =                 {record type stored in original fileblock}
    record
      dele : longint;
      string1 : string[10];
      string2 : string[10];
      varies : string;      {variable length string at end}
    end;
  newrect =                 {record type stored in reorganized fileblock}
    record
      dele : longint;
      string1 : string[10];
      string2 : string[10];
      string3 : string[10]; {added field in reorganized fileblock}
      varies : string;
    end;

type
  oldfb =                   {object type for original fileblock}
    object(vfileblock)
      function BuildKey(var Rec; KeyNr : Word) : IsamKeyStr; virtual;
      function EqualRec(var Rec1, Rec2) : Boolean; virtual;
      {---> note: must override RecLen in variable length fileblock}
      function RecLen(var Rec) : Word; virtual;
    end;

  newfb =                   {object type for reorganized fileblock}
    object(vfileblock)
      function BuildKey(var Rec; KeyNr : Word) : IsamKeyStr; virtual;
      function EqualRec(var Rec1, Rec2) : Boolean; virtual;
      function RecLen(var Rec) : Word; virtual;
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
              (oldrect(rec1).string2 = oldrect(rec2).string2) and
              (oldrect(rec1).varies = oldrect(rec2).varies);
end;

function oldfb.RecLen(var Rec) : Word;
  {-Return record length of old variable length record}
begin
  reclen := sizeof(oldrect)-sizeof(string)+length(oldrect(rec).varies)+1;
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
              (newrect(rec1).string3 = newrect(rec2).string3) and
              (newrect(rec1).varies = newrect(rec2).varies);
end;

function newfb.ConvertRec(var OldRec, NewRec; var Len : Word) : Boolean;
  {-Convert records from old format to new format}
begin
  {Only non-deleted records are passed to this routine}
  newrect(newrec).dele := 0;
  {Copy old fields to new record}
  newrect(newrec).string1 := oldrect(oldrec).string1;
  newrect(newrec).string2 := oldrect(oldrec).string2;
  newrect(newrec).varies := oldrect(oldrec).varies;
  {Initialize new field of new record}
  newrect(newrec).string3 := 'new';
  {Pass back length of new record}
  inc(Len, 11); {11 = sizeof(newrect.string3)}
  ConvertRec := true;
end;

function newfb.RecLen(var Rec) : Word;
  {-Return record length of new variable length record}
begin
  reclen := sizeof(newrect)-sizeof(string)+length(newrect(rec).varies)+1;
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
  if not o.create('junk', sectlen, 2, iid,
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
    {Build artificial varying length string}
    fillchar(orec.varies[1], i shr 1, 'z');  {varying length string}
    orec.varies[0] := char(i shr 1);
    o.addrecord(ref, orec);
    checkok;
  end;

  {Display number of sections in old fileblock}
  writeln('initial section count ', o.totalrecs);
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
  {--> note: not a requirement for section length before and after to be equal}
  if not n.reorganize('junk',                          {file name}
                      sectlen, sectlen,                {section lengths}
                      3, iid,                          {indexes}
                      sizeof(newrect)-sizeof(oldrect), {maxdiffbytes}
                      false,                           {addnull}
                      false, false, false, false)      {open mode}
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
        writeln(nrec.string1:4, ' ', nrec.string2,
                ' ', nrec.string3, ' ', nrec.varies);
    end;
  end;

  {Show number of sections in reorganized fileblock}
  writeln('reorganized section count ', n.totalrecs);
  {Delete the demo fileblock}
  n.delete;
end;

begin
  if BTInitIsam(NoNet, MinimizeUseOfNormalHeap, 0) = 0 then halt;
  if not BTSetVariableRecBuffer(SectLen) then halt;
  makeold;
  reorgnew;
  BTExitIsam;
end.
