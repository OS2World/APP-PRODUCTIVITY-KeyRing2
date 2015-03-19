program Search_Path; {demo program for WCSearch unit}

{Example program for the WCSearch unit}

uses
  DOS, WCSearch;

var
  S : String;
  R : SearchRec;
  I : Integer;

procedure EndIt(S : String);
begin
  WriteLn(S);
  Halt(1);
end;

begin
  if ParamCount < 1 then
    EndIt('Syntax: SRCHPATH [filespec] {path_to_search | *}');
  if ParamCount > 1 then begin
    S := ParamStr(2);
    if S[1] = '*' then S := GetEnv('PATH');
  end
  else
    S := '';

  I := 0;
  FindFirstWC(ParamStr(1),S,AnyFile,R,S);
  while DOSError = 0 do begin
    WriteLn(S+R.Name);
    inc(I);
    FindNextWC(R,S);
  end;

  if I = 0 then
    WriteLn('No matching files')
  else begin
    Write(I,' file');
    if I > 1 then Write('s');
    WriteLn(' found');
  end;
end.
