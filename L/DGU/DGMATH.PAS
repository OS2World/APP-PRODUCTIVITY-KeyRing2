{**************************************************************************
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
* Generic financial math and string functions
*
* Released to public domain, 1/9/97
*
* Kevin G. McCoy
* President, IDK, Inc.
*
* Please send updates, bug fixes and additions to
* kgmccoy@idk-inc.com
*
* ~notesend~
*
***************************************************************************

}
{$IFDEF VirtualPascal}
{$H-}
{$ENDIF}

{$A+,B-,D+,E-,F-,G+,I-,L+,N+,O+,P+,Q-,R-,S-,T-,V-,X+,Y+}
UNIT DGMath;

INTERFACE
USES
    OpDate,
    OpRoot,
    OpString
    {$IFDEF VirtualPascal}
    ,Use32
    {$ENDIF}
    ;

CONST
    DegreesToRadians = 0.01745;
    MinComp        = - 9.223372037e18;
    MaxComp        = 9.223372037e18;
    CompRange      = 1.844674407e19;
    MinExtended    = 3.37e-4932;
    MaxExtended    = 1.18e4932;

    AlphaSet       : CharSet = ['A'..'Z'];
    MixedAlphaSet  : CharSet = ['A'..'Z', 'a'..'z'];
    NumSet         : CharSet = ['0'..'9'];
    PunctSet       : CharSet = [' '..'/'];

    {calc compound interest}
FUNCTION CompoundInterest(Princ, Interest, TimesPerYr, Years : REAL) : REAL;

    {translate longint value to dollars string}
FUNCTION Long2Dollars(V : LONGINT; SuppressDollars, BlankZero : BOOLEAN) : STRING;

    {translate longint value to dollars.cents string; V is in cents units}
FUNCTION Long2Cents(V : LONGINT; SuppressDollars, BlankZero : BOOLEAN) : STRING;

    {translate real value to dollars string}
FUNCTION Real2Dollars(V : REAL; SuppressDollars, BlankZero : BOOLEAN) : STRING;

FUNCTION LongWithCommas(V : LONGINT; BlankZero : BOOLEAN) : STRING;

    {translate longint value to dollars string (in K)}
FUNCTION Long2KiloBucks(V : LONGINT) : STRING;

    {translate longint to percent}
FUNCTION Long2Pct(V : LONGINT; BlankZero : BOOLEAN) : STRING;

    {translate real to percent string with variable precision}
FUNCTION Real2Pct(V : REAL; D, P : BYTE) : STRING;

    {create a random real value, between Min and Max}
FUNCTION RandReal(Min, Max : REAL) : REAL;
FUNCTION RandDouble(Min, Max : Double) : Double;

    {create a random long value, between Min and Max, inclusive}
FUNCTION RandLongRange(Min, Max : LONGINT) : LONGINT;

    {create a random COMP value, between Min and Max, inclusive}
FUNCTION RandCompRange(Min, Max : COMP) : COMP;

    {return a random positive real}
FUNCTION RandPosLong : LONGINT;

FUNCTION RandBool : BOOLEAN;

    {return boolean with TRUE Pct probability 100.0 = every time; 0 = never}
FUNCTION RandBoolBias(Pct : REAL) : BOOLEAN;

    {return a random signed long (32 bit) integer}
FUNCTION RandLong : LONGINT;

    {return a random IP address string in the format of "192.168.0.1"}
FUNCTION RandIPString : STRING;

    {create personal names}
FUNCTION RandFullName : STRING;
FUNCTION RandFirstName : STRING;
FUNCTION RandLastName : STRING;
    {create random single char; uppercase alpha}
FUNCTION RandChar : STRING;
    {upper/lower+numeric; no control chars or high ascii}
FUNCTION RandCharDeluxe : CHAR;
    {return random deluxe string}
FUNCTION RandStr(MinLen, MaxLen : BYTE) : STRING;

    {returns random strings limited to the contents of the charset}
FUNCTION RandStringLimited(MinLen, MaxLen : BYTE; CS : CharSet) : STRING;

    {create random company name}
FUNCTION RandCompanyName : STRING;
    {create random phone number with area code, USA style}
FUNCTION RandPhoneNumber : STRING;

    {random address strings}
FUNCTION RandState : STRING;
FUNCTION RandAddress : STRING;
FUNCTION RandZip(NineDigit : BOOLEAN) : STRING;
FUNCTION RandZipAuto : STRING;    {randomly make 5/9 digit zips}
FUNCTION RandURL : STRING;
    {create random dollar string ranging between min and max cents}
FUNCTION RandDollars(MinCents, MaxCents : LONGINT) : STRING;

    {create random date string ranging between min and max opro dates}
FUNCTION RandDate(MinDate, MaxDate : Date) : STRING;

    {create random date string and DTR ranging between min and max opro dates}
FUNCTION RandDTR(MinDate, MaxDate : Date; VAR DTR : DateTimeRec) : STRING;

    {return the lowest value found in a or b}
FUNCTION MinReal(A, B : REAL) : REAL;

    {return the highest value found in a or b}
FUNCTION MaxReal(R1, R2 : REAL) : REAL;

    {caluclate age in years based on birthdate and current date}
FUNCTION CalcMyAge(BDay : Date) : BYTE;

FUNCTION CalcMyAgeInMonths(BDay : Date) : WORD;

FUNCTION CalcMyAgeInWeeks(BDay : Date) : WORD;

FUNCTION CalcMyAgeOnDate(BDay, WhenDate : Date) : WORD;

    {return currency string (dollars) from longint value with variable formatting }
FUNCTION Long2Currency(Picture : STRING; V : LONGINT) : STRING;

    {return string containing the value of L, blank zero values}
FUNCTION LongIntFormZeroBlank(Mask : STRING; L : LONGINT) : STRING;
FUNCTION ArcSin(X : REAL) : REAL;
FUNCTION ArcCos(X : REAL) : REAL;

    {swap longint order to put bytes in motorola order}
FUNCTION UnIntelLong(L : LONGINT) : LONGINT;
    {swap longint order to put bytes in reverse bit order}
FUNCTION ReverseBits(L : LONGINT) : LONGINT;

    {return longint containing IP address described in Octet:  192.168.0.1}
FUNCTION OctetToLong(N1, N2, N3, N4 : BYTE) : LONGINT;
    {given IP address and mask, does Candidate IP address match?  Use OctetToLong for the three addresses}
FUNCTION IPAddrMatch(IP, Mask, Candidate : LONGINT) : BOOLEAN;
    {given IP address, return the 4 octets}
PROCEDURE LongToOctet(IP : LONGINT; VAR N1, N2, N3, N4 : BYTE);
    {given dotted IP address string, return IP in longint form}

    {turn "192.168.0.1" into long int}
FUNCTION OctetStringToLong(Strg : STRING) : LONGINT;

    {given IP in longint form, return dotted IP address string}
FUNCTION LongToOctetString(IP : LONGINT) : STRING;

    {convert longint into roman numerals string}
FUNCTION LongToRomanNumerals(L : LONGINT) : STRING;

    {Linear Feedback Shift Register random number generator, using shrinking generator}
    {Applied Cryptography, 2nd Edition, Schneier, 1996}

TYPE
    {Single LFSR}
    PLFSR          = ^TLFSR;
    TLFSR          = OBJECT(ROOT)
                         CONSTRUCTOR InitRandomize;
                         CONSTRUCTOR Init(Seed : LONGINT);
                         FUNCTION LFSRShift : BOOLEAN;

                     PRIVATE
                         ShiftRegister  : LONGINT;
                     END;

    {random byte generator with 64 bit seed                   }
    {this object does not affect the randseed global variable,}
    {so it is safe to create multiple random TRandGen objects }

    PRanGen        = ^TRanGen;
    TRanGen        = OBJECT(ROOT)
                         {instantiate and create random seed}
                         CONSTRUCTOR InitRandomize;

                         {instantiate and seed LFSRs with user supplied 64 bit seed}
                         CONSTRUCTOR Init(Seed : COMP);
                         CONSTRUCTOR InitStrg(Seed : STRING);

                             {return a random byte}
                         FUNCTION RandByte : BYTE;

                         DESTRUCTOR Done; VIRTUAL;

                     PRIVATE
                             {pointers to the two lfsr objects}
                         LFSR1,
                         LFSR2          : PLFSR;

                             {shrinking generator}
                         FUNCTION GenerateBit : BOOLEAN;
                     END;


IMPLEMENTATION
USES
    STRCRC,
    OpAbsFld,
    OpInline,
    Strings,
    UTTIMDAT;

    { A = P(1+i/m)^(mn) }
    { Where
      P = Principal
      i = Interest, in percent (8.0 = 8%)
      m = interest payment frequency/yr
      n = years}
    FUNCTION CompoundInterest(Princ, Interest, TimesPerYr, Years : REAL) : REAL;
    VAR
        X,
        Y              : REAL;
    BEGIN
        Interest := Interest / 100.0;
        Y := (1 + (Interest / TimesPerYr));
        X := TimesPerYr * Years;
        X := EXP(X * LN(Y));      {x^y}
        CompoundInterest := Princ * X;
    END;

    {-------------}

    FUNCTION Long2Dollars(V : LONGINT; SuppressDollars, BlankZero : BOOLEAN) : STRING;
    BEGIN
        IF (V = 0) AND BlankZero THEN BEGIN
            Long2Dollars := '';
            EXIT;
        END;
        IF SuppressDollars THEN
            Long2Dollars := Trim(LongIntForm('###,###,###', V))
        ELSE
            Long2Dollars := Trim(LongIntForm('$###,###,###', V));
    END;

    {-------------}

    FUNCTION LongWithCommas(V : LONGINT; BlankZero : BOOLEAN) : STRING;
    BEGIN
        IF (V = 0) AND BlankZero THEN BEGIN
            LongWithCommas := '';
            EXIT;
        END;
        LongWithCommas := Trim(LongIntForm('###,###,###,###', V))
    END;

    {-------------}

    {translate longint value to dollars.cents string; V is in cents units}
    FUNCTION Long2Cents(V : LONGINT; SuppressDollars, BlankZero : BOOLEAN) : STRING;
    VAR
        R              : REAL;
    BEGIN
        IF (V = 0) AND BlankZero THEN BEGIN
            Long2Cents := '';
            EXIT;
        END;

        R := V / 100.0;

        IF SuppressDollars THEN
            Long2Cents := Trim(Form('###,###,###.##.', R))
        ELSE
            Long2Cents := Trim(Form('$###,###,###.##', R));
    END;


    {-------------}

    {translate real value to dollars string}
    FUNCTION Real2Dollars(V : REAL; SuppressDollars, BlankZero : BOOLEAN) : STRING;
    VAR
        Strg1,
        Strg           : STRING;
        N              : BYTE;
    BEGIN
        IF (V = 0) AND BlankZero THEN BEGIN
            Real2Dollars := '';
            EXIT;
        END;

        IF SuppressDollars THEN
            Real2Dollars := Trim(Form('###,###,###.##', V))
        ELSE
            Real2Dollars := Trim(Form('$###,###,###.##', V));
    END;

    {-------------}

    FUNCTION Long2KiloBucks(V : LONGINT) : STRING;
    VAR
        R              : REAL;
    BEGIN
        R := V / 1000.0;
        Long2KiloBucks := Trim(LongIntForm('$###,###,###', ROUND(R)));
    END;

    {-------------}

    FUNCTION Long2Pct(V : LONGINT; BlankZero : BOOLEAN) : STRING;
    BEGIN
        IF (V = 0) AND BlankZero THEN
            Long2Pct := ''
        ELSE
            Long2Pct := Trim(LongIntForm('###%', V));
    END;

    {-------------}

    FUNCTION Real2Pct(V : REAL; D, P : BYTE) : STRING;
    VAR
        Strg           : STRING;
    BEGIN
        STR(V:D:P, Strg);
        Real2Pct := Strg + '%';
    END;

    {-------------}

    FUNCTION MinReal(A, B : REAL) : REAL;
    BEGIN
        MinReal := A;

        IF A > B THEN
            MinReal := B;
    END;

    {-------------}

    FUNCTION MaxReal(R1, R2 : REAL) : REAL;
    BEGIN
        IF R1 < R2 THEN
            MaxReal := R2
        ELSE
            MaxReal := R1;
    END;

    {-------------}

    FUNCTION CalcMyAge(BDay : Date) : BYTE;
    VAR
        D,
        M,
        Y              : INTEGER;
    BEGIN
        IF BDay <> BADDate THEN
            DateDiff(Today, BDay, D, M, Y)
        ELSE
            Y := 0;
        IF Y > 255 THEN
            Y := 255;
        CalcMyAge := Y;
    END;

    {-------------}

    FUNCTION CalcMyAgeOnDate(BDay, WhenDate : Date) : WORD;
    VAR
        D,
        M,
        Y              : INTEGER;
    BEGIN
        IF BDay <> BADDate THEN
            DateDiff(WhenDate, BDay, D, M, Y)
        ELSE
            Y := 0;
        IF Y > 255 THEN
            Y := 255;
        CalcMyAgeOnDate := Y;
    END;

    {-------------}

    FUNCTION CalcMyAgeInMonths(BDay : Date) : WORD;
    VAR
        D,
        M,
        Y              : INTEGER;
    BEGIN
        IF BDay <> BADDate THEN
            DateDiff(Today, BDay, D, M, Y)
        ELSE
            Y := 0;
        IF Y > 255 THEN
            Y := 255;
        Y := (Y * 12) + M;
        CalcMyAgeInMonths := Y;
    END;

    {-------------}

    FUNCTION CalcMyAgeInWeeks(BDay : Date) : WORD;
    VAR
        Diff           : LONGINT;
    BEGIN
        Diff := Today - BDay;
        CalcMyAgeInWeeks := TRUNC(Diff / 7);
    END;

    {-------------}

    FUNCTION RandBool : BOOLEAN;
    BEGIN
        RandBool := RANDOM(1000) > 500;
    END;

    {-------------}

    FUNCTION RandBoolBias(Pct : REAL) : BOOLEAN;
    BEGIN
        RandBoolBias := RANDOM(1000) > ROUND((100.0 - Pct) * 10);
    END;

    {-------------}

    FUNCTION RandPosLong : LONGINT;
    BEGIN
        RandPosLong := MakeLongInt(RANDOM($8001), MakeWord(RANDOM($100), RANDOM($100)));
    END;

    {-------------}

    {create a random long integer using the pascal random number generator}
    FUNCTION RandLong : LONGINT;
    BEGIN
        RandLong := MakeLongInt(MakeWord(RANDOM($100), RANDOM($100)), MakeWord(RANDOM($100), RANDOM($100)));
    END;

    {-------------}

    {create a random long value, between Min and Max, inclusive}
    FUNCTION RandLongRange(Min, Max : LONGINT) : LONGINT;
    VAR
        T,
        R,
        M              : REAL;
        L              : LONGINT;
    BEGIN
        R := Max - Min;
        M := RandPosLong / 2147483647.0;
        T := Min + (R * M);
        L := ROUND(T);
        IF L < Min THEN
            L := Min;
        IF L > Max THEN
            L := Max;
        RandLongRange := L;
    END;

    {-------------}

TYPE
    TCOMP          = RECORD
                         L1,
                         L2             : LONGINT;
                     END;

    FUNCTION RandPosComp : COMP;
    VAR
        R              : TCOMP;
        T              : COMP ABSOLUTE R;
    BEGIN
        R.L1 := RandPosLong;
        R.L2 := RandLong;
        RandPosComp := T;
    END;

    {-------------}

    {create a random COMP value, between Min and Max, inclusive}
    FUNCTION RandCompRange(Min, Max : COMP) : COMP;
    VAR
        T,
        R,
        M              : EXTENDED;
        L              : COMP;
    BEGIN
        R := Max - Min;
        M := RandPosComp / MaxComp;
        T := Min + (R * M);
        L := T;
        IF L < Min THEN
            L := Min;
        IF L > Max THEN
            L := Max;
        RandCompRange := L;
    END;

    {-------------}

    FUNCTION RandReal(Min, Max : REAL) : REAL;
    VAR
        T,
        R,
        M              : REAL;
        L              : LONGINT;
    BEGIN
        R := Max - Min;
        M := RandPosLong / 2147483647.0;
        T := Min + (R * M);
        RandReal := T;
    END;

    {-------------}

    FUNCTION RandDouble(Min, Max : Double) : Double;
    VAR
        T,
        R,
        M              : Double;
        L              : LONGINT;
    BEGIN
        R := Max - Min;
        M := RandPosLong / 2147483647.0;
        Result := Min + (R * M);
    END;

    {-------------}

    FUNCTION RandExtended(Min, Max : extended) : extended;
    VAR
        R,
        M              : extended;
    BEGIN
        R := Max - Min;
        M := RandPosComp / MaxExtended;
        Result := Min + (R * M);
    END;

    {-------------}

    FUNCTION RandChar : STRING;
    BEGIN
        RandChar := CHAR(RANDOM(26) + ORD('A'))
    END;

    {-------------}

    FUNCTION RandCompanySuffix : STRING;
    VAR
        Strg           : STRING;
    BEGIN
        CASE RANDOM(7) OF
            0 :
                RandCompanySuffix := ', Inc.';
            1 :
                RandCompanySuffix := ' Corp';
            2 :
                RandCompanySuffix := ' Ltd';
            3 :
                RandCompanySuffix := ' & Sons';
            4 :
                RandCompanySuffix := '';
            5 :
                RandCompanySuffix := ' LLC';
            6 :
                RandCompanySuffix := ' Gmbh';
        END;
    END;

    {-------------}
CONST
    FirstSyl       : ARRAY[0..248] OF PCHAR =
    (
        'Ab', 'Ac', 'Ad', 'Ag', 'Ah', 'Ai', 'Ak', 'Al', 'Am', 'An', 'Ap', 'Ar', 'As', 'At', 'Au', 'Av', 'Aw', 'Ax', 'Ay', 'Az',
        'Ba', 'Be', 'Bi', 'Bl', 'Bo', 'Br', 'Bu', 'By',
        'Ca', 'Ce', 'Ch', 'Ci', 'Cl', 'Co', 'Cr', 'Cu', 'Cy',
        'Da', 'De', 'Dh', 'Di', 'Dl', 'Do', 'Dr', 'Du', 'Dy',
        'Ea', 'Eb', 'Ec', 'Ed', 'Ef', 'Eg', 'Eh', 'Ei', 'Ek', 'El', 'Em', 'En', 'Eo', 'Ep', 'Equ', 'Er', 'Es', 'Et', 'Eu',
        'Ev', 'Ew', 'Ex', 'Ey', 'Ez',
        'Fa', 'Fe', 'Fi', 'Fl', 'Fo', 'Fr', 'Fu', 'Fy',
        'Ga', 'Ge', 'Gh', 'Gi', 'Gl', 'Go', 'Gr', 'Gu', 'Gw', 'Gy',
        'Ha', 'He', 'Hi', 'Ho', 'Hu', 'Hy',
        'Ia', 'Ic', 'Id', 'Ie', 'If', 'Ig', 'Ih', 'Ii', 'Ik', 'Il', 'Im', 'In', 'Io', 'Ip', 'Ir', 'Is', 'It', 'Ix', 'Iz',
        'Ja', 'Je', 'Jh', 'Ji', 'Jo', 'Ju', 'Jy',
        'Ka', 'Ke', 'Ki', 'Kl', 'Kn', 'Ko', 'Kr', 'Ku', 'Ky',
        'La', 'Le', 'Li', 'Lo', 'Lu', 'Ly',
        'Ma', 'Me', 'Mi', 'Mo', 'Mu', 'My',
        'Na', 'Ne', 'Ni', 'No', 'Nu', 'Ny',
        'Ob', 'Oc', 'Od', 'Of', 'Og', 'Oh', 'Oi', 'Ok', 'Ol', 'Om', 'On', 'Oo', 'Op', 'Oq', 'Or', 'Os', 'Ou', 'Ov', 'Ow',
        'Ox', 'Oy', 'Oz',
        'Pa', 'Pe', 'Ph', 'Pi', 'Pl', 'Po', 'Pr', 'Pu', 'Py',
        'Qu',
        'Ra', 'Re', 'Rh', 'Ri', 'Rl', 'Ro', 'Ru', 'Ry',
        'Sa', 'Sc', 'Se', 'Sh', 'Si', 'Sk', 'Sl', 'Sm', 'Sn', 'So', 'Sp', 'Squ', 'Sr', 'St', 'Su', 'Sw', 'Sy',
        'Ta', 'Te', 'Th', 'Ti', 'To', 'Tr', 'Tu', 'Ty',
        'Ug', 'Uk', 'Ul', 'Um', 'Un', 'Up', 'Ur', 'Us', 'Ut', 'Uv',
        'Va', 'Ve', 'Vi', 'Vo', 'Vu', 'Vy',
        'Wa', 'We', 'Wh', 'Wi', 'Wo', 'Wr', 'Wu', 'Wy',
        'Xa', 'Xe', 'Xi', 'Xo', 'Xu', 'Xy',
        'Za', 'Ze', 'Zi', 'Zo', 'Zu', 'Zy', 'Zz'
        );

    LastSyl        : ARRAY[0..16] OF PCHAR =
    (
        'tran',
        'tron',
        'tronics',
        'most',
        'man',
        'trope',
        'fon',
        'dyne',
        '',
        'del',
        'sco',
        'co',
        'nod',
        'mo',
        'no',
        'oid',
        'fram'
        );

    CompSufx       : ARRAY[0..24] OF PCHAR =
    (
        'Co.',
        'Inc.',
        'Company',
        'Group',
        'International',
        'LLC.',
        'Ltd.',
        'Fund',
        'Estates',
        'Ranch',
        'Gmbh',
        'Incorporated',
        'Financial',
        'Manufacturing',
        'Machining',
        'Research',
        'Storage',
        'Chemical',
        'Shipping',
        'Aircraft',
        'Travel',
        'Construction',
        'Shipyards',
        'Spacecraft',
        'Systems'
        );

    CompList       : ARRAY[0..27] OF PCHAR =
    (
        'ABC Corp', 'IDK Inc.', 'Great Stuff', 'Microsoft',
        'Borland, Inc.', 'Turbo-Power software', 'XYZ Big Company', 'Big company',
        'Yellow House, Inc.', 'ICS Incorporated', 'Prudential Securities, Inc.', 'North American Fire Hose',
        'Mitan', 'Amplica, Inc.', '3DBM, Inc.', 'Amgen, Inc.',
        'Systron Donner', 'ClassicPlan', 'The Design Group', 'Milestone Technologies, Inc.',
        'Brilliant Data, Ltd.', 'Utoptics, Inc.', 'Anritsu, Inc.', 'AFI, Inc.',
        'AT-Computers', 'Best Power', 'Utoptics, Inc.', 'Arrowfield International'
        );

    FirstNameList  : ARRAY[0..66] OF PCHAR =
    (
        'Jack', 'Jim', 'Joe', 'Bob', 'Bill', 'Kevin', 'Sam', 'John', 'Jeff', 'Rodney',
        'Mathew', 'Martin', 'Mary', 'Jane', 'Jill', 'Carl', 'David', 'William', 'Linda',
        'Evan', 'Roger', 'David', 'Kirk', 'Keith', 'Ray', 'Luanne', 'Joyce', 'Melinda',
        'Cheryl', 'Sandy', 'Susan', 'Vladimir', 'Sanford', 'Fred', 'Johan', 'Rae',
        'Joshua', 'Maureen', 'Gabrielle', 'Andrea', 'Nader', 'Howard', 'Carol', 'Miganoosh',
        'Mark', 'Larry', 'Colleen', 'Len', 'Brett', 'Darryl', 'Scott', 'Anne',
        'Alan', 'Arnold', 'Elaine', 'Jorene', 'Peggy', 'Joanne', 'Kerry',
        'Kathy', 'Joanna', 'Donald', 'Howard', 'Lenore', 'Johan', 'John',
        'Aleta'
        );
    LastNameList   : ARRAY[0..57] OF PCHAR =
    (
        'Beam', 'Daniels', 'Misery', 'Blow', 'Smith', 'Jones', 'Black',
        'Brown', 'Green', 'Evans', 'Rogers', 'Cassady', 'Pickens',
        'McCoy', 'Hansen', 'Kostritsa', 'Hunt', 'Hope', 'Bradley',
        'Pahls', 'Neely', 'Levi', 'Clague', 'Fuchs', 'Gordon',
        'Greenwald', 'Grossman', 'Hanna', 'Hendrix', 'King', 'Antonio',
        'Anicker', 'Alpine', 'Best', 'Barakat', 'Blau', 'Bush', 'Harotunians',
        'Benson', 'Malmquist', 'Crawford', 'Tara', 'Roland', 'Boyer',
        'Booth', 'Rosen', 'Shepard', 'London', 'Grief', 'Watson',
        'Harris', 'Hamil', 'Norman', 'Searle', 'Sheets', 'Minkova',
        'Knight', 'Walker'
        );

    FUNCTION RandCompanyName : STRING;
    VAR
        Strg           : STRING;
        I              : BYTE;
    BEGIN
        CASE RANDOM(10) OF
            0,
            1,
            2 :
                BEGIN             {30% chance of random sylable name}
                    Strg := '';
                    FOR I := 1 TO RANDOM(3) + 1 DO
                        Strg := Strg + StLocase(StrPas(FirstSyl[RANDOM(SUCC(HIGH(FirstSyl)))]));
                    Strg[1] := UPCASE(Strg[1]);
                    RandCompanyName := Strg + StrPas(LastSyl[RANDOM(SUCC(HIGH(LastSyl)))]) + ' ' +
                                       StrPas(CompSufx[RANDOM(SUCC(HIGH(CompSufx)))]);
                END;
            3,                    {30% chance of random actual company name}
            4,
            5 :
                RandCompanyName := StrPas(CompList[RANDOM(SUCC(HIGH(CompList)))]);
            6,                    {20% chance of a 3 letter initial company name}
            7 :
                BEGIN
                    Strg := '';
                    FOR I := 1 TO 3 DO
                        Strg := Strg + RandChar;
                    Strg := Strg + RandCompanySuffix;
                    RandCompanyName := Strg;
                END;
            8,                    {20% chance of 3 name partnership company name}
            9 :
                RandCompanyName := RandLastName + ', ' + RandLastName + ' & ' + RandLastName + RandCompanySuffix;
        END;
    END;

    {-------------}

CONST
    URLList        : ARRAY[0..13] OF PCHAR =
    (
        'idk-inc.com',
        'west.net',
        'ibm.net',
        'yahoo.com',
        'hotbot.com',
        'aol.com',
        'compuserve.com',
        'abac.com',
        'ebay.com',
        'netscape.com',
        'quicken.com',
        'bmtmicro.com',
        'lycos.com',
        'goto.com'
        );


    FUNCTION RandURL : STRING;
    BEGIN
        RandURL := 'http://www.' + StrPas(URLList[RANDOM(SUCC(HIGH(URLList)))]);
    END;

    {-------------}

    FUNCTION RandPhoneNumber : STRING;
    BEGIN
        RandPhoneNumber := '(' +
                           LeftPadCh(Long2Str(RandLongRange(100, 999)), '0', 3) +
                           ') ' +
                           LeftPadCh(Long2Str(RandLongRange(100, 999)), '0', 3) +
                           '-' +
                           LeftPadCh(Long2Str(RandLongRange(0000, 9999)), '0', 4);
    END;

    {-------------}

    FUNCTION RandStreet : STRING;
    BEGIN
        CASE RANDOM(11) OF
            0 :
                RandStreet := 'St.';
            1 :
                RandStreet := 'Ave';
            2 :
                RandStreet := 'Pl';
            3 :
                RandStreet := 'Ct.';
            4 :
                RandStreet := 'Blvd';
            5 :
                RandStreet := 'Way';
            6 :
                RandStreet := 'Circle';
            7 :
                RandStreet := 'Parkway';
            8 :
                RandStreet := 'Hwy';
            9 :
                RandStreet := 'Rd';
            10 :
                RandStreet := 'Lane';
        END;

    END;

    {-------------}

    FUNCTION RandAddress : STRING;
    BEGIN
        RandAddress := Long2Str(RandLongRange(0000, 9999)) +
                       ' ' +
                       RandLastName +
                       ' ' +
                       RandStreet;
    END;

    {-------------}

    FUNCTION RandZip(NineDigit : BOOLEAN) : STRING;
    VAR
        Strg           : STRING;
    BEGIN
        Strg := LeftPadCh(Long2Str(RandLongRange(0, 99999)), '0', 5);
        IF NineDigit THEN
            Strg := Strg +
                    '-' +
                    LeftPadCh(Long2Str(RandLongRange(0, 9999)), '0', 4);
        RandZip := Strg;
    END;

    {-------------}

    FUNCTION RandZipAuto : STRING;
    BEGIN
        RandZipAuto := RandZip(RandBool);
    END;

    {-------------}

    FUNCTION RandDollars(MinCents, MaxCents : LONGINT) : STRING;
    BEGIN
        RandDollars := Long2Cents(RandLongRange(MinCents, MaxCents), FALSE, FALSE);
    END;

    {-------------}

    FUNCTION RandDate(MinDate, MaxDate : Date) : STRING;
    BEGIN
        RandDate := DateToDateString('mm/dd/yy', RandLongRange(MinDate, MaxDate));
    END;

    {-------------}

    {create random date string and DTR ranging between min and max opro dates}
    FUNCTION RandDTR(MinDate, MaxDate : Date; VAR DTR : DateTimeRec) : STRING;
    BEGIN
        DTR.D := RandLongRange(MinDate, MaxDate);
        DTR.T := RandLongRange(0, SecondsInDay);
        RandDTR := DTRtoString(DTR);
    END;

    {-------------}

    FUNCTION RandState : STRING;
    CONST
        StateStrings   : ARRAY[0..50] OF STRING[2] = (
              {00} 'AK', {01} 'AL', {02} 'AR',
              {03} 'AZ', {04} 'CA', {05} 'CO',
              {06} 'CT', {07} 'DC', {08} 'DE',
              {09} 'FL', {10} 'GA', {11} 'HI',
              {12} 'IA', {13} 'ID', {14} 'IL',
              {15} 'IN', {16} 'KS', {17} 'KY',
              {18} 'LA', {19} 'MA', {20} 'MD',
              {21} 'ME', {22} 'MI', {23} 'MN',
              {24} 'MO', {25} 'MS', {26} 'MT',
              {27} 'NC', {28} 'ND', {29} 'NE',
              {30} 'NH', {31} 'NJ', {32} 'NM',
              {33} 'NV', {34} 'NY', {35} 'OH',
              {36} 'OK', {37} 'OR', {38} 'PA',
              {39} 'RI', {40} 'SC', {41} 'SD',
              {42} 'TN', {43} 'TX', {44} 'UT',
              {45} 'VA', {46} 'VT', {47} 'WA',
              {48} 'WI', {49} 'WV', {50} 'WY');
    BEGIN
        RandState := StateStrings[RANDOM(HIGH(StateStrings) + 1)];
    END;

    {-------------}

    FUNCTION RandFirstName : STRING;
    BEGIN
        RandFirstName := StrPas(FirstNameList[RANDOM(SUCC(HIGH(FirstNameList)))]);
    END;

    {-------------}

    FUNCTION RandLastName : STRING;
    BEGIN
        RandLastName := StrPas(LastNameList[RANDOM(SUCC(HIGH(LastNameList)))]);
    END;

    {-------------}

    FUNCTION RandFullName : STRING;
    VAR
        Strg           : STRING;
    BEGIN
        Strg := RandFirstName + ' ';

        IF RANDOM(100) < 60 THEN
            Strg := Strg + RandChar + '. ';

        RandFullName := Strg + RandLastName;
    END;

    {-------------}

    {-Initialize a picture flags table}

    PROCEDURE InitPictureFlags(AfPicture : STRING; VAR PFlags : PictureFlags; AfMaxLen : BYTE);
        {-Initialize a picture flags table}
    CONST
        PictureChars   : SET OF CHAR = [
        AnyChar, ForceUp, ForceLo, ForceMixed, AlphaOnly, UpperAlpha,
        LowerAlpha, NumberOnly, DigitOnly, Scientific, HexOnly,
        BooleanOnly, YesNoOnly,
        {$IFDEF UseDates}
        NameOnly, NameOnlyU,
        MonthOnly, DayOnly, YearOnly, HourOnly, MinOnly, SecOnly,
        MonthOnlyU, DayOnlyU, HourOnlyU, MinOnlyU, SecOnlyU, TimeOnly, EmOnly,
        {$ENDIF}
        User1..User8];
    VAR
        I              : WORD;
        P              : STRING;
    BEGIN
        FILLCHAR(PFlags[AfMaxLen + 1], SIZEOF(PFlags) - AfMaxLen, FALSE);
        P := AfPicture;
        FOR I := 1 TO AfMaxLen DO
            PFlags[I] := (P[I] IN PictureChars);
    END;

    {-------------}

    PROCEDURE StripPicture(VAR S1, S2, AfPicture : STRING);
        {-Strip picture characters out of S1 and return in S2}
    VAR
        SLen           : BYTE ABSOLUTE S2;
        Flags          : PictureFlags;
        I,
        J,
        FDP            : WORD;
        Picture        : STRING;
    BEGIN
        Picture := AfPicture;
        IF LENGTH(S1) <> LENGTH(Picture) THEN BEGIN
            S2 := S1;
            EXIT;
        END;

        InitPictureFlags(AfPicture, Flags, LENGTH(AfPicture));

        I := POS(DecimalPt, Picture);
        IF I <> 0 THEN
            Flags[I] := TRUE;

        FDP := POS(FloatDollar, Picture);
        IF FDP <> 0 THEN BEGIN
            WHILE (Picture[FDP] = FloatDollar) DO BEGIN
                Flags[FDP] := TRUE;
                INC(FDP);
            END;
        END;

        FOR J := 1 TO LENGTH(Picture) DO
            IF Picture[J] = Comma THEN
                Flags[J] := TRUE;

        SLen := 0;
        FOR I := 1 TO LENGTH(Picture) DO
            IF Flags[I] THEN BEGIN
                INC(SLen);
                S2[SLen] := S1[I];
            END;

        IF FDP <> 0 THEN BEGIN
            I := POS(CurrencyLtStr, S2);
            IF I <> 0 THEN
                DELETE(S2, I, LENGTH(CurrencyLtStr));
        END;

        IF POS(Comma, Picture) <> 0 THEN BEGIN
            REPEAT
                I := POS(CommaChar, S2);
                IF I <> 0 THEN
                    DELETE(S2, I, 1);
            UNTIL (I = 0);
        END;

        IF POS(DecimalPt, Picture) <> 0 THEN BEGIN
            I := POS(DecimalChar, S2);
            IF I <> 0 THEN
                S2[I] := '.';
        END;
    END;

    {-------------}

    {-Merge St with Picture and return result in S}
    FUNCTION Long2Currency(Picture : STRING; V : LONGINT) : STRING;
    VAR
        Width,
        Places,
        DotPosP,
        DotPosS,
        FloatPos,
        I,
        J,
        K,
        N              : WORD;
        Flags          : PictureFlags;
        IsNumber,
        NeedMinus,
        NeedFloat      : BOOLEAN;
        TempCurrency   : STRING[5];
        TClen          : BYTE ABSOLUTE TempCurrency;
        S,
        St             : STRING;
        SLen           : BYTE ABSOLUTE S;
        StLen          : BYTE ABSOLUTE St;
    BEGIN
        St := Long2Str(V);
        S := Picture;
        DotPosP := POS(DecimalPt, Picture);
        InitPictureFlags(Picture, Flags, SLen);

        {is it a numeric string?}
        IsNumber := TRUE {afIsNumber} ;

        {take care of currency strings}
        I := POS(CurrencyLt, Picture);
        IF I <> 0 THEN BEGIN
            K := I;
            WHILE (K < SLen) AND (S[K + 1] = CurrencyLt) DO
                INC(K);
            J := LENGTH(CurrencyLtStr);
            FOR N := K DOWNTO I DO
                IF J > 0 THEN BEGIN
                    S[N] := CurrencyLtStr[J];
                    DEC(J);
                END
                ELSE
                    S[N] := ' ';
        END;
        I := POS(CurrencyRt, Picture);
        IF I <> 0 THEN BEGIN
            J := 1;
            WHILE (I <= SLen) AND (Picture[I] = CurrencyRt) DO BEGIN
                IF J <= LENGTH(CurrencyRtStr) THEN
                    S[I] := CurrencyRtStr[J]
                ELSE
                    S[I] := ' ';
                INC(I);
                INC(J);
            END;
        END;

        IF IsNumber THEN BEGIN
            {see if we need to strip picture characters}
            IF (StLen = SLen) AND (POS(DecimalPt, St) {DotPosS} = DotPosP) THEN {!!.11}
                StripPicture(St, St, S);

            {we need to fill in the FloatDollar positions too, if any}
            FloatPos := POS(FloatDollar, Picture);
            IF FloatPos <> 0 THEN BEGIN
                TempCurrency := CurrencyLtStr;
                WHILE Picture[FloatPos] = FloatDollar DO BEGIN
                    Flags[FloatPos] := TRUE;
                    INC(FloatPos);
                END;
                DEC(FloatPos);
            END
            ELSE
                TClen := 0;

            {trim leading and trailing blanks}
            TrimSpacesPrim(St);

            {check for a minus sign}
            NeedMinus := (StLen > 0) AND (St[1] = '-');
            IF NeedMinus THEN
                DELETE(St, 1, 1);

            {it's a numeric field--align the decimal points}
            DotPosS := POS(DecimalPt, St);

            {see if we need a floating dollar sign}
            IF StLen = 0 THEN
                NeedFloat := FALSE
            ELSE
                NeedFloat := TClen <> 0;

            {if there's no tail, pretend there's a dot beyond the end of St}
            IF DotPosS = 0 THEN
                K := StLen + 1
            ELSE
                K := DotPosS;

            {copy the tail of the string}
            IF DotPosP = 0 THEN
                I := SLen + 1
            ELSE
                I := DotPosP + 1;
            J := K + 1;
            WHILE (J <= StLen) AND (I <= SLen) AND Flags[I] DO BEGIN
                S[I] := St[J];
                INC(I);
                INC(J);
            END;

            {pad to end with 0's}
            WHILE (I <= SLen) AND Flags[I] DO BEGIN
                S[I] := '0';
                INC(I);
            END;

            {handle substitution characters} {!!.14}
            WHILE (I <= SLen) AND NOT Flags[I] DO BEGIN {!!.14}
                CASE Picture[I] OF {!!.14}
                    Subst1..Subst8 : S[I] := SubstChars[Picture[I]]; {!!.14}
                END;              {!!.14}
                INC(I);           {!!.14}
            END;                  {!!.14}

            {copy the front of the string}
            IF DotPosP = 0 THEN
                J := SLen
            ELSE
                J := DotPosP;
            IF DotPosS <> 0 THEN
                StLen := DotPosS - 1;
            FOR I := J DOWNTO 1 DO
                IF Flags[I] THEN BEGIN
                    IF (StLen <> 0) AND (I > FloatPos) THEN BEGIN
                        S[I] := St[StLen];
                        DEC(StLen);
                    END
                    ELSE IF NeedFloat THEN BEGIN
                        S[I] := TempCurrency[TClen];
                        DEC(TClen);
                        NeedFloat := TClen <> 0;
                    END
                    ELSE IF NeedMinus THEN BEGIN
                        S[I] := '-';
                        NeedMinus := FALSE;
                    END
                    ELSE
                        S[I] := ' ';
                END
                ELSE CASE Picture[I] OF
                    Subst1..Subst8 : {!!.02}
                        S[I] := SubstChars[Picture[I]]; {!!.02}
                    DecimalPt :
                        S[I] := DecimalChar;
                    Comma :
                        IF (StLen <> 0) THEN
                            S[I] := CommaChar
                        ELSE IF NeedFloat THEN BEGIN
                            S[I] := TempCurrency[TClen];
                            DEC(TClen);
                            NeedFloat := TClen <> 0;
                        END
                        ELSE IF NeedMinus THEN BEGIN
                            S[I] := '-';
                            NeedMinus := FALSE;
                        END
                        ELSE
                            S[I] := ' ';
                END;

            {put in a 0 before the dot if necessary}
            IF DotPosP <> 0 THEN BEGIN
                I := DotPosP - 1;
                IF (S[I] = ' ') THEN
                    S[I] := '0';
            END;
        END;
        Long2Currency := S;
    END;

    {-------------}

    {-Returns a formatted string with digits from L merged into the Mask}
    { blanks zero values.}
    FUNCTION LongIntFormZeroBlank(Mask : STRING; L : LONGINT) : STRING;
    VAR
        S              : STRING[20];
    BEGIN
        S := LongIntForm(Mask, L);
        IF Trim(S) = '0' THEN
            S := '';
        LongIntFormZeroBlank := Trim(S);
    END;

    {-------------}

CONST
    Mask           = $80000057;

    {-------------}

    CONSTRUCTOR TRanGen.InitRandomize;
    VAR
        ORS            : LONGINT;
    BEGIN
        {initialize parent object}
        IF NOT INHERITED Init THEN
            FAIL;

        ORS := RANDSEED;          {preserve Pascal's global randseed}

        {seed Pascal random number generator with local time}
        RANDOMIZE;

        {instantiate two LFSRs and seed with random longints}
        NEW(LFSR1, InitRandomize);
        NEW(LFSR2, InitRandomize);

        IF LFSR2 = NIL THEN BEGIN {fail if out of heap}
            RANDSEED := ORS;
            FAIL;
        END;

        {recover the old randseed}
        RANDSEED := ORS;
    END;

    {-------------}

    CONSTRUCTOR TRanGen.Init(Seed : COMP);
    VAR
        T              : ARRAY[1..2] OF LONGINT ABSOLUTE Seed;
    BEGIN
        {initialize parent object}
        IF NOT INHERITED Init THEN
            FAIL;

        {instantiate two LFSRs, using the upper and lower longints}
        {found in the 64 bit seed                                 }
        NEW(LFSR1, Init(T[1]));   {use upper 32 bits of seed}
        NEW(LFSR2, Init(T[2]));   {use lower 32 bits of seed}

        IF LFSR2 = NIL THEN       {fail if out of heap}
            FAIL;
    END;

    {-------------}

    CONSTRUCTOR TRanGen.InitStrg(Seed : STRING);
    BEGIN
        IF NOT TRanGen.Init(Calc64BitCRC(Seed)) THEN
            FAIL
    END;

    {-------------}

    {shrinking generator}
    FUNCTION TRanGen.GenerateBit : BOOLEAN;
    VAR
        B1,
        B2             : BOOLEAN;
    BEGIN
        {shift both SRs until b1 goes true, then use b2's output}
        REPEAT
            B1 := LFSR1^.LFSRShift;
            B2 := LFSR2^.LFSRShift;
            IF B1 THEN BEGIN
                GenerateBit := B2; {set return value}
                BREAK;            {break loop on b1 true}
            END;
        UNTIL FALSE;              {loop forever}
    END;

    {-------------}

    {build an 8bit byte using random bits from GenerateBit}
    FUNCTION TRanGen.RandByte : BYTE;
    VAR
        I,
        R              : BYTE;
    BEGIN
        R := 0;
        FOR I := 0 TO 7 DO BEGIN
            IF GenerateBit THEN
                R := R OR (1 SHL I);
        END;
        RandByte := R;
    END;

    {-------------}

    {dispose of dynamically allocated objects to free heap}
    DESTRUCTOR TRanGen.Done;
    BEGIN
        INHERITED Done;           {kill parent}
        DISPOSE(LFSR1, Done);     {kill children}
        DISPOSE(LFSR2, Done);
    END;

    {-------------}

    {seed an LFSR with a random long integer from Pascal}
    CONSTRUCTOR TLFSR.InitRandomize;
    BEGIN
        ShiftRegister := RandLong;
        IF ShiftRegister = 0 THEN {0 seeds are not allowed!}
            INC(ShiftRegister);   {bump it to 1}
    END;

    {-------------}

    {seed an LFSR with a 32bit random seed provided by the user}
    CONSTRUCTOR TLFSR.Init(Seed : LONGINT);
    BEGIN
        ShiftRegister := Seed;
        IF ShiftRegister = 0 THEN {0 seeds are not allowed!}
            INC(ShiftRegister);   {bump it to 1}
    END;

    {-------------}

    {32 bit linear feedback shift register}
    {generates a random single bit stream}
    {This algorithm is lifted almost verbatim from Applied Cryptography, 2nd Edition}
    FUNCTION TLFSR.LFSRShift : BOOLEAN;
    BEGIN
        LFSRShift := FALSE;
        IF (ShiftRegister AND 1) = 1 THEN BEGIN
            ShiftRegister := ((ShiftRegister XOR Mask) SHR 1) OR $80000000;
            LFSRShift := TRUE;
        END
        ELSE
            ShiftRegister := ShiftRegister SHR 1;
    END;

    {-------------}

    FUNCTION ArcSin(X : REAL) : REAL;
    BEGIN
        ArcSin := ARCTAN(X / SQRT(1 - SQR(X)));
    END;

    {-------------}

    FUNCTION ArcCos(X : REAL) : REAL;
    BEGIN
        ArcCos := ARCTAN(SQRT(1 - SQR(X)) / X);
    END;

    {-------------}

    FUNCTION RandIPString : STRING;
    BEGIN
        RandIPString :=
            Long2Str(RandLongRange(0, 255)) +
            '.' +
            Long2Str(RandLongRange(0, 255)) +
            '.' +
            Long2Str(RandLongRange(0, 255)) +
            '.' +
            Long2Str(RandLongRange(0, 255));
    END;

    {-------------}

    FUNCTION OctetToLong(N1, N2, N3, N4 : BYTE) : LONGINT;
    VAR
        L              : LONGINT;
        B              : ARRAY[1..4] OF BYTE ABSOLUTE L;
    BEGIN
        B[4] := N1;
        B[3] := N2;
        B[2] := N3;
        B[1] := N4;
        OctetToLong := L;
    END;

    {-------------}

    PROCEDURE LongToOctet(IP : LONGINT; VAR N1, N2, N3, N4 : BYTE);
    VAR
        B              : ARRAY[1..4] OF BYTE ABSOLUTE IP;
    BEGIN
        N1 := B[4];
        N2 := B[3];
        N3 := B[2];
        N4 := B[1];
    END;

    {-------------}

    FUNCTION OctetStringToLong(Strg : STRING) : LONGINT;
    VAR
        I              : BYTE;
        L,
        IP             : LONGINT;
    BEGIN
        IP := 0;
        FOR I := 1 TO 4 DO BEGIN
            IF NOT Str2Long(ExtractWord(5 - I, Strg, ['.']), L) THEN {index through period delimited string}
                L := 0;           {trap bad chars in string}
            IF L > 255 THEN
                L := 255;         {trap out of range values}
            INC(IP, L SHL ((I - 1) * 8)); {accumulate shifted values of octet}
        END;
        OctetStringToLong := IP;
    END;

    {-------------}

    FUNCTION LongToOctetString(IP : LONGINT) : STRING;
    VAR
        N1,
        N2,
        N3,
        N4             : BYTE;
    BEGIN
        LongToOctet(IP, N1, N2, N3, N4);
        LongToOctetString := Long2Str(N1) + '.' +
                             Long2Str(N2) + '.' +
                             Long2Str(N3) + '.' +
                             Long2Str(N4);
    END;

    {-------------}

    FUNCTION IPAddrMatch(IP, Mask, Candidate : LONGINT) : BOOLEAN;
    BEGIN
        IF Candidate = - 1 THEN BEGIN {255.255.255.255 is broadcast address}
            IPAddrMatch := TRUE;
            EXIT;
        END
        ELSE
            IPAddrMatch := ((IP AND Mask) XOR (Candidate AND Mask)) = 0;
    END;

    {-------------}

TYPE
    RomRec         = RECORD
                         Divisor        : LONGINT;
                         Zto3           : CHAR;
                         Four,
                         FiveTo8Pri     : STRING[2];
                         FiveTo8Sec     : CHAR;
                         Nine           : STRING[2];
                     END;
CONST
    {lookup table for roman numeral decades}
    RomanTable     : ARRAY[1..5] OF RomRec =
    (
        (Divisor : 1; Zto3 : 'I'; Four : 'IV'; FiveTo8Pri : 'V'; FiveTo8Sec : 'I'; Nine : 'IX'),
        (Divisor : 10; Zto3 : 'X'; Four : 'XL'; FiveTo8Pri : 'L'; FiveTo8Sec : 'X'; Nine : 'XC'),
        (Divisor : 100; Zto3 : 'C'; Four : 'CD'; FiveTo8Pri : 'D'; FiveTo8Sec : 'C'; Nine : 'CM'),
        (Divisor : 1000; Zto3 : 'M'; Four : 'XV'; FiveTo8Pri : 'V'; FiveTo8Sec : 'C'; Nine : 'IX'),
        (Divisor : 10000; Zto3 : 'X'; Four : 'IV'; FiveTo8Pri : 'V'; FiveTo8Sec : 'I'; Nine : 'IX')
        );

    {-------------}

    {build a roman numberal decade}
    FUNCTION BuildRoman(VAR L          : LONGINT;
                        CONST R        : RomRec) : STRING;
    VAR
        Strg           : STRING;
    BEGIN
        BuildRoman := '';
        WITH R DO BEGIN
            IF L < Divisor THEN   {decade too large, try smaller one}
                EXIT;
            CASE L DIV Divisor OF {where are we within decade?}
                0..3 :
                    Strg := CharStr(Zto3, L DIV Divisor); {handle trivial case}
                4 :
                    Strg := Four; {handle subtractive case}
                5..8 :
                    {handle fifth, through 8th case }
                    Strg := FiveTo8Pri + CharStr(FiveTo8Sec, (L DIV Divisor) - 5);
                9 :
                    Strg := Nine; {handle subtractive ninth case}
                ELSE
                    Strg := '';   {paranoia}
            END;
            L := L MOD Divisor;   {decrement value by current decade}
        END;
        BuildRoman := Strg;       {return the string}
    END;

    {-------------}

    FUNCTION LongToRomanNumerals(L : LONGINT) : STRING;
    VAR
        Strg           : STRING;
        I              : BYTE;
    BEGIN
        IF L < 100000 THEN
            Strg := ''
        ELSE BEGIN
            LongToRomanNumerals := 'Overrange!';
            EXIT;
        END;
        IF L > 0 THEN BEGIN
            FOR I := HIGH(RomanTable) DOWNTO 1 DO {work backwards}
                Strg := Strg + BuildRoman(L, RomanTable[I]); {concatenate the decade strings}
        END
        ELSE
            Strg := 'Underrange!';
        LongToRomanNumerals := Strg;
    END;

    {-------------}

    FUNCTION RandCharDeluxe : CHAR;
    BEGIN
        RandCharDeluxe := CHAR(RANDOM(94) + ORD(' '))
    END;

    {-------------}

    FUNCTION RandStr(MinLen, MaxLen : BYTE) : STRING;
    VAR
        Strg           : STRING;
        I              : BYTE;
    BEGIN
        Strg := '';
        FOR I := 1 TO RandLongRange(MinLen, MaxLen) DO
            Strg[I] := RandCharDeluxe;
        Strg[0] := CHAR(I - 1);
        RandStr := Strg;
    END;

    {-------------}

    {returns random strings limited to the contents of the charset}
    FUNCTION RandStringLimited(MinLen, MaxLen : BYTE; CS : CharSet) : STRING;
    VAR
        Strg           : STRING;
        I              : BYTE;
        L              : BYTE;
        C              : CHAR;
    BEGIN
        L := RandLongRange(MinLen, MaxLen);
        Strg := '';
        WHILE LENGTH(Strg) < L DO BEGIN
            REPEAT
                C := CHAR(RANDOM(256));
                IF C IN CS THEN BEGIN
                    Strg := Strg + C;
                    BREAK;
                END;
            UNTIL FALSE;
        END;
        RandStringLimited := Strg;
    END;

    {-------------}

    {swap longint order to put bytes in motorola order}
    FUNCTION UnIntelLong(L : LONGINT) : LONGINT;
    VAR
        B              : ARRAY[1..4] OF BYTE ABSOLUTE L;
        T              : LONGINT;
        Tr             : ARRAY[1..4] OF BYTE ABSOLUTE T;
    BEGIN
        Tr[1] := B[4];
        Tr[2] := B[3];
        Tr[3] := B[2];
        Tr[4] := B[1];
        UnIntelLong := T;
    END;

    {-------------}

    {swap longint order to put bytes in reverse bit order}
    FUNCTION ReverseBits(L : LONGINT) : LONGINT;
    VAR
        B              : ARRAY[1..4] OF BYTE ABSOLUTE L;
        T              : LONGINT;
        Tr             : ARRAY[1..4] OF BYTE ABSOLUTE T;
    BEGIN
        Tr[1] := B[4];
        Tr[2] := B[3];
        Tr[3] := B[1];
        Tr[4] := B[2];
        ReverseBits := T;
    END;

    {-------------}

    {$IFNDEF DLL}
BEGIN
    RANDOMIZE;
    {$ENDIF DLL}
END.

    {-------------}
    {-------------}
