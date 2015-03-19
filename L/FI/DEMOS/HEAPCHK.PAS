(* V 1.05 Bonus  Copyright (C) 1991/92  ENZ EDV-BERATUNG GMBH *)
(*                All rights reserved                         *)
(*   Modified and used under license by TurboPower Software   *)

Unit HeapChk;

{$R-,S-,F+}

Interface
  Procedure InstallHeapErrorFunc;
  Procedure DeInstallHeapErrorFunc;

Implementation

Const
  OldHeapError : Pointer = Nil;

  Function HeapCheck ( ASize : Word ) : Integer; far;
  Begin
    If ( HeapError <> Nil ) Then
      ASM
        PUSH    ASize
        CALL    OldHeapError;
      End;
    HeapCheck := 1;
  End;

  Procedure InstallHeapErrorFunc;
  Begin
    OldHeapError := HeapError;
    HeapError := @HeapCheck;
  End;

  Procedure DeInstallHeapErrorFunc;
  Begin
    If OldHeapError <> Nil Then Begin
      HeapError := OldHeapError;
      OldHeapError := Nil;
    End;
  End;

End.
