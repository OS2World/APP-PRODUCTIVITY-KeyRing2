/* */
    Rc = RXFUNCADD("KRULoadFuncs", "KRUTIL", "KRULoadFuncs")
    SAY "krUloadfuncs result " || Rc
    CALL Kruloadfuncs
    SAY "made it past krUloadfuncs"
    H = Krhexxer("123456")

    SAY "hexxer result = " || H

    Rc = RXFUNCADD("KRLoadFuncs", "KRINI", "KRLoadFuncs")
    SAY "krlf result " || Rc
    CALL Krloadfuncs
    SAY "made it past krloadfuncs"

    Rc = Kropenini("kr2.dat", "aa")
    SAY "open ini success = " || Rc
    Rt = 4
    SAY Krgetreccount(Rt)

    DO I=1 TO Krgetreccount(Rt)
        	say Krgetrec(Rt, I)
    END
