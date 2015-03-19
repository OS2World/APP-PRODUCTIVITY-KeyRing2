{$IFNDEF DPMI}
      !! ERROR: This DLL is for protected mode *ONLY*        {!!.TP}
{$ENDIF}

Library Win87EM;

Function __FPMATH : Word; Export; Assembler;

Asm
  Xor AX, AX
  RetF
End;

Exports
 __FPMATH Index 1;

Begin
End.
