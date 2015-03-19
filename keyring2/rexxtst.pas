{$B-,D+,H-,I-,J+,P-,Q+,R+,S+,T-,V-,W+,X+,Z-}
{&AlignCode+,AlignData-,AlignRec-,Asm-,Delphi+,Frame+,G3+,LocInfo+,Open32-}
{&Optimise-,OrgName-,SmartLink+,Speed-,Use32-,ZD+}
{$M 500000}
program rexxtst;
uses
    OS2DEF,
    OS2Rexx,
    smini;

type
    PParamArray = ^TParamArray;
    TParamArray = array[1..10] of RxString;

procedure doit;
var
    Pars : TParamArray;
    ParsP : PParamArray;
    Rc : ULONG;
    Ret : RxString;
const
    Par1 : RxString = (strlength:8; strptr:'addrx.ini');
    Par2 : RxString = (strlength:1; strptr:'1');
    Par3 : RxString = (strlength:9; strptr:'broadcast');
    RootPars : Tparamarray =
    (
         (strlength:9; strptr:'>:addrrouting:broadcast'),
         (strlength:1; strptr:'1'),
         (strlength:9; strptr:'broadcast'),
         (strlength:9; strptr:'broadcast'),
         (strlength:9; strptr:'broadcast'),
         (strlength:9; strptr:'broadcast'),
         (strlength:9; strptr:'broadcast'),
         (strlength:9; strptr:'broadcast'),
         (strlength:9; strptr:'broadcast'),
         (strlength:9; strptr:'broadcast')
    );
begin
    Rc := smOpenINI('Openini', 1, @Par1, 'queue', Ret);
    Rc := smGetGroupCount('getgroupcount', 0, @par1, 'queue', ret);
    Rc := smGetNthGroup('GetNthGroup', 0, @par2, 'queue', ret);

    Rc := smGetNthAddr('GetNthAddr', 0, @rootpars, 'queue', ret);
    Rc := smGetNthMask('GetNthMask', 0, @rootpars, 'queue', ret);
    Rc := smGetNthadrLoc('GetNthadrLoc', 0, @rootpars, 'queue', ret);
    Rc := smGetNthAdrIcon('GetNthIcon', 0, @rootpars, 'queue', ret);
    Rc := smGetNthAdrName('GetNthAdrName', 0, @rootpars, 'queue', ret);

    Rc := smDisposeINI('DisposeINI', 0, @par2, 'queue', ret);

end;

begin
    Doit;
end.
