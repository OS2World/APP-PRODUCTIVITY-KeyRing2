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
*
* ~notesend~
* ~nokeywords~
*
****************************************************************************
}
{$A+,B-,E+,F-,G+,I+,N+,O+,P-,Q+,R+,S+,T-,V-,X+,Y+}
UNIT UTLCS;

    {$V-}

    {$V-}
    {$O+}
INTERFACE

USES
    OpCRT,
    OpCtrl;

CONST
    otLoadableDColorSet = 1100;
    veLoadableDColorSet = 0;

PROCEDURE GetColorSet(Name : STRING; VAR Colors : ColorSet);
PROCEDURE GetdColorSet(Name : STRING; VAR Colors : DialogColorSet);
    (****************************************************************************)

IMPLEMENTATION


USES
    Dos,
    {MRLow,}
    OpWindow,
    OpRoot,
    OpDialog,
    OpString;

    (****************************************************************************)
TYPE

    LoadableDColorSet = OBJECT(ROOT)
                            LCSColors      : DialogColorSet;
                            CONSTRUCTOR Init(VAR Colors : DialogColorSet);
                            CONSTRUCTOR Load(VAR S : IDSTREAM);
                            PROCEDURE Store(VAR S : IDSTREAM);
                        END;
    (****************************************************************************)

    CONSTRUCTOR LoadableDColorSet.Init(VAR Colors : DialogColorSet);
        {-Initialize this color set from another one}
    BEGIN
        IF NOT ROOT.Init THEN
            FAIL;
        LCSColors := Colors;
    END;

    (****************************************************************************)

    CONSTRUCTOR LoadableDColorSet.Load(VAR S : IDSTREAM);
        {-Load a color set from a stream}
    BEGIN
        IF NOT ROOT.Init THEN
            FAIL;

        S.READ(LCSColors, SIZEOF(LCSColors));
        IF S.PeekStatus <> 0 THEN BEGIN
            Done;
            FAIL;
        END;
    END;
    (****************************************************************************)

    PROCEDURE LoadableDColorSet.Store(VAR S : IDSTREAM);
        {-Store a color set in a stream}
    BEGIN
        S.WRITE(LCSColors, SIZEOF(LCSColors));
    END;

    (****************************************************************************)

    PROCEDURE LoadableDColorSetStream(SPTR : IdStreamPtr); FAR;
        {-Register all types needed for streams containing loadable color sets}
    BEGIN
        SPTR^.RegisterType(otLoadableDColorSet, veLoadableDColorSet,
                           TYPEOF(LoadableDColorSet),
                           @LoadableDColorSet.Store, @LoadableDColorSet.Load);
    END;

    (****************************************************************************)

    PROCEDURE GetColorSet(Name : STRING; VAR Colors : ColorSet);
        {- Load a colorset file }
    VAR
        LCS            : LoadableColorSet;
        S              : BufIDSTREAMPTR;
        Status         : WORD;
        StartPath      : PathStr;
    BEGIN
        NEW(S, Init(ForceExtension(Name, 'LCS'), SOpen, 1024));
        IF S = NIL THEN BEGIN
            StartPath := AddBackSlash(JustPathName(PARAMSTR(0)));
                {DispErrorDeluxe('Can''t find filename: ' + Name,
                                'Creating default color file', TRUE, Iam);}
            NEW(S, Init(StartPath + ForceExtension(Name, 'LCS'), SCreate, 1024));
            IF S = NIL THEN
                EXIT;
            WITH S^ DO BEGIN
                RegisterHier(LoadableColorsetStream);
                Status := GetStatus;
                LCS.Init(Colors);
                Put(LCS);
            END;
            DISPOSE(S, Done);
        END
        ELSE BEGIN
            S^.RegisterHier(LoadableColorsetStream);
            S^.Get(LCS);
            DISPOSE(S, Done);
            Colors := LCS.LCSColors;
        END;
    END;

    (****************************************************************************)


    PROCEDURE GetdColorSet(Name : STRING; VAR Colors : DialogColorSet);
        {- Load a dialog colorset file }
    VAR
        LCS            : LoadableDColorSet;
        S              : BufIdStream;
        Status         : WORD;
        StartPath      : PathStr;
    BEGIN
        IF NOT S.Init(ForceExtension(Name, 'LCS'), SOpen, 1024) THEN BEGIN
            Status := S.GetStatus;
            IF Status = 0 THEN BEGIN
                {DispErrorDeluxe('Can''t find filename: ' + Name,
                                'Creating default color file',
                                TRUE, Iam);}
                StartPath := AddBackSlash(JustPathName(PARAMSTR(0)));
                S.Init(StartPath + ForceExtension(Name, 'LCS'), SCreate, 1024);
                Status := S.GetStatus;
                S.RegisterHier(LoadableDColorSetStream);
                LCS.Init(Colors);
                S.Put(LCS);
                S.Done;
            END;
            {
            ELSE
                DispErrorDeluxe('Problem loading file: ' + Name,
                                'Try reinstalling software ' + ErrorMessage(Status),
                                TRUE, Iam);}
        END
        ELSE BEGIN
            S.RegisterHier(LoadableDColorSetStream);
            S.Get(LCS);
            S.Done;
            Colors := LCS.LCSColors;
        END;
    END;

    {unit initialization}

END.                              {of unit ncolor}
(****************************************************************************)
(****************************************************************************)
