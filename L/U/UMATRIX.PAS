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
* ~notesend~
* ~nokeywords~
*
****************************************************************************

}
{$A-,R-,S-,V-,O+,F+}

{---------------------------------------------------------}
{ (C) 1990 NewsMaker Systems.                             }
{ Search matrix processor for Btree multi-key searches    }
{---------------------------------------------------------}

Unit UMatrix;

interface

Uses Dos,Printer,
     OpCrt;

Const
  NumElements  = 3000; { Record hit matrix size }

Type
  Matrix_Element = Record
                     Ref  : LongInt;
                     Hits : Word;
                   end;
  Matrix_Array   = Array[1..NumElements] of Matrix_Element;
  MatrixPtr      = ^Matrix_Array;

  SearchMatrix   = Object
    SMatrix : MatrixPtr;
    Ptr     : word;
    Filter  : word;
    OverFlow: boolean;
    constructor Init;
    destructor Done;
    procedure Add(Ref: LongInt);
    function  Found: word;
    function  Filtered: word;
    Procedure GetElement(Num: word;var Rec: LongInt;var HitCount: Word);
    procedure Reset;
    end;
  SearchPtr = ^SearchMatrix;

Const
  FilterMode      :  boolean = False;
Var
  Matrix          :  SearchPtr;

implementation

{--------------------------------------------------------------------}
{ >> SearchMatrix methods }

constructor SearchMatrix.Init;
  begin
    New(SMatrix);
    Ptr := 0;
    Filter := 0;
    OverFlow := false;
  end;

destructor SearchMatrix.Done;
  begin
    if SMatrix <> nil then
      Dispose(SMatrix);
  end;

Procedure SearchMatrix.Add(Ref: LongInt);
  var I: word;
  begin
    if Ptr = 0 then
      begin
        inc(Ptr);
        Smatrix^[Ptr].Ref := Ref;
        Smatrix^[Ptr].Hits := 1;
      end
    else
      begin
        for I := 1 to ptr do
          if Smatrix^[I].Ref = Ref then
            begin
              inc(Smatrix^[I].Hits);
              exit;
            end;
        if not FilterMode then
          begin
            inc(Ptr);
            if Ptr > NumElements then
              begin
                overflow := true;
                exit;
              end;
            Smatrix^[Ptr].Ref := Ref;
            Smatrix^[Ptr].Hits := 1;
          end
        else
          inc(Filter);
      end;
  end;

Function SearchMatrix.Found: Word;
  begin
    Found := Ptr;
  end;

Function SearchMatrix.Filtered: Word;
  begin
    Filtered := Filter;
  end;

Procedure SearchMatrix.GetElement(Num: word;var Rec: LongInt;var HitCount: Word);
  begin
    if Num <= Ptr then
      begin
        Rec := Smatrix^[Num].Ref;
        HitCount := Smatrix^[Num].Hits;
      end;
  end;

Procedure SearchMatrix.Reset;
  begin
    Ptr := 0;
    OverFlow := false;
    Filter := 0;
  end;

End.
