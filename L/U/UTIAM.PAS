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
* Function to return address of line of code in BP7
* or VP/2.  Works in Real, Pmode or 32 bit OS/2.
*
* ~notesend~
* ~nokeywords~
*
****************************************************************************
}
{$A+,B-,D+,E+,F+,G+,I-,L+,N+,O+,P-,Q-,R-,S-,T-,V-,X+,Y+}

UNIT UTIAM;

INTERFACE

FUNCTION Iam   : POINTER;
PROCEDURE ClearErrorAddr;

IMPLEMENTATION


    (*****************)

    { returns return address of code calling Iam.  Works with both }
    { overlayed and non overlayed TP code                          }

    { value returned is the same as if you got a runtime error at  }
    { the Iam() call.  Also sets the SYSTEM.ERRORADDR global value }
    { for post mortem debugging                                    }

    { Dont forget to call ClearErrorAddr prior to normal shutdown, }
    { or it is likely that UERROR will falsely trap the bogus      }
    { ERRORADDR                                                    }

    { Usage: WRITELN(HexPtr(Iam)); displays the MAP address of the }
    { WRITELN line on the crt                                      }

    { Alternate usage:  cut and paste the assy code into the freemem}
    { function;  modify the "MOV BX, [BP+4]" and "MOV CX, [BP+2]"  }
    { lines to use a different offset to BP.  BP points to the     }
    { bottom of the function stackframe.  Use an offset that moves }
    { the [BP+x] address to the top of the stackframe-4 bytes, and }
    { the Iam  code will turn into a WhoCalledMe function          }

    { You have to examine the disassembled code with Turbo Debugger}
    { to find out the stack frame size for a given function. The   }
    { easiest way is to compile with 286 instructions, and look for}
    { the "enter xxxx,d" assembly code with TD.  The xxxx value is }
    { the stackframe size.                                         }

    { Adding, removing or changing vars, passed params or          }
    { "implicit temporary vars" will affect the stack frame size   }

    { K. McCoy 9-93}
VAR
    IAMLast        : POINTER;

    {- returns pointer to current line address from MAP file              }
    {actually, this function returns a pointer containing Iam's own return}
    {address, regardless of the codes location (overlayed, root or DPMI)  }
    {The address retured will be searchable using the Find:Error feature  }
    {of the IDE or the standalone compiler.  This makes it useful to      }
    {locate error addresses when trapping errors in user code.            }

    FUNCTION Iam   : POINTER;
    BEGIN
        {$IFDEF VirtualPascal}
        ASM
            MOV     EAX, [EBP+4]    {ret adr seg- no stkfrm, on this guy}
            MOV     Result, EAX
        END;
        {$ELSE}
        ASM
            MOV     BX, [BP+4]    {ret adr seg- no stkfrm, on this guy}
            MOV     CX, [BP+2]    {ret adr ofs}
            {$IFNDEF DPMI}
            MOV     AX, OVRLOADLIST {are we overlayed?}
@12c:
            OR      AX, AX
            JE      @15f          {noovr}
            MOV     ES, AX        {es points to olays - loop and find self}
            MOV     AX,ES:[$10]
            OR      AX,AX
            JE      @155
            SUB     AX,BX
            JA      @155
            NEG     AX
            CMP     AX, $1000
            JNB     @155
            MOV     DX, $10
            MUL     DX
            ADD     AX, CX
            JB      @155
            CMP     AX,ES:[$8]
            JB      @15b
@155:
            MOV     AX,ES:[$14]
            JMP     @12c
@15b:
            MOV     CX,AX
            MOV     BX,ES
@15f:
            SUB     BX, PREFIXSEG {map address offset from core address}
            SUB     BX, $10

            MOV     [OFFSET ERRORADDR], CX
            MOV     [OFFSET ERRORADDR+2], BX
            {$ELSE}               {pmode}
            mov     ax,cx
            or      ax,bx
            je      @2b5     {check for nil return address}
            verr    bx
            je      @2ae
            mov     bx,$ffff {Error: force address to ffff:ffff}
            mov     cx,bx
            jmp     @2b5
@2ae:       mov     es,bx    {get selector offset?}
            mov     bx,es:[0]
@2b5:       MOV     [OFFSET ERRORADDR], CX {offset}
            MOV     [OFFSET ERRORADDR+2], BX {segment (selector)}
            {$ENDIF}
        END;
        IAMLast := ERRORADDR;
        Iam := IAMLast;
        {$ENDIF}
    END;

    (*****************)

    PROCEDURE ClearErrorAddr;
    BEGIN
        ERRORADDR := NIL;
    END;

    (*****************)

END.
