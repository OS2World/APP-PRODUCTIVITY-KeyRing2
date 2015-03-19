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
{$A-,B-,F+,I-,L+,N-,R-,S-,V-}
{$IFNDEF Windows}
{$O+}
{$ENDIF}
{.$M 16384,0,655360}

UNIT URLINE;

(*********************************************************************
                   Fast disk file text reading operations.

        Address comments, complaints, suggestions on CompuServe to
                       Don Strenczewilk [72617,132]


    This unit contains a fast reading object designed for high speed
    reading standard ASCII disk files.

    The RLINE unit uses about 600 bytes of your programs code space,
    and 0 data.

    All of RLobject's methods return the result of their operation in
    the RFerror field, except for methods: FFilePos and FClose, which
    have no error codes.  RFerror should be checked after each call to
    one of the methods that set it, because it is re-set with each
    method call.

**********************************************************************)
INTERFACE
    (*********************************************************************)

USES
    {$IFNDEF Windows}
    Dos;
    {$ELSE}
  WinDos,
  WinDPMI;
  {$ENDIF}

TYPE
    RFobject       = OBJECT
                         _Handle        : WORD; { File handle }
                         _BufPtr        : POINTER; { BufOfs, BufSeg}
                         _Bpo,    { Current buffer position }
                         _BSize,  { Buffer size in bytes }
                         _BLeft,  { Bytes left in buffer to scan }
                         _NBufs         : WORD; { Number of buffers read. = 0 if none. }
                         _TotBytesInBuf : WORD; { Total bytes that were read into current buffer.}
                         RFerror        : WORD; { RFobject's IOResult }

                         PROCEDURE FOpen(Fn             : STRING; { Name of file to open. }
                                         DBSize         : WORD; { Size of buffer. 512 bytes minimum. }
                                         VAR BufP); { Disk buffer to use. }
                         PROCEDURE FClose;
                         PROCEDURE FReadLn(VAR S : STRING); { String variable to read next line to. }
                         PROCEDURE FRead(VAR Ch : CHAR); { Char variable to read next line to. }
                         FUNCTION FFilePos : LONGINT;
                         PROCEDURE FSeek(FPo : LONGINT);
                     END;


    RFextendedP    = ^RFextended;
    RFextended     = OBJECT(RFobject)
                         FileName       : STRING[80];

                         CONSTRUCTOR Init(Fn             : STRING; { Name of file to open. }
                                          DBSize         : WORD; { Size of buffer. }
                                          VAR BufP); { Address of disk buffer }
                         DESTRUCTOR Done;
                         FUNCTION FILESIZE : LONGINT;
                         FUNCTION RFerrorString : STRING;
                         PROCEDURE RESET;
                     END;

TYPE
    BufRec         = RECORD
                         Lno            : LONGINT; { The first line number in the buffer }
                         FP             : LONGINT; { file position of first line in buffer. }
                     END;
CONST
    MaxBufs        = 8191;

TYPE
    BufferArray    = ARRAY[1..MaxBufs] OF BufRec;
    PBufferArray   = ^BufferArray;


CONST
    PermTBuf       : PBufferArray = NIL;

TYPE

{ When FileOfLines is initialized with SizeForBuffer = 256, it can index
  files up to 2,096,896 bytes long.
{ With SizeForBuffer = 4096, it will handle files up to 33,550,336 bytes. }

    FileOfLinesPtr = ^FileOfLines;
    FileOfLines    = OBJECT(RFextended)
                         TBuf           : POINTER; { Disk buffer pointer. }
                         BufSize        : INTEGER; { Disk buffer size. }
                         LastLineNum    : LONGINT; { Last line number accessed. }
                         LastLine       : STRING; { Last line read. }
                         TotalLines     : LONGINT; { Total lines in file. }
                         BufRay         : PBufferArray; { Index of buffers for paging. }
                         NBuffers       : INTEGER;

                         CONSTRUCTOR Init(Fn             : STRING;
                                          SizeForBuffer  : WORD);
                         DESTRUCTOR Done;
                         PROCEDURE SeekLine(Row : LONGINT);
                         FUNCTION ReturnBuffAdr(VAR NBuffs     : INTEGER;
                                                VAR TLS        : LONGINT)
                         : PBufferArray;
                     END;

(*---------------------------------------------------------------------
PROCEDURE RFobject.FOpen

A file must first be successfully opened with a call to FOpen, before any of
the other routines are used.

A buffer must be declared to be passed the FOpen.  There are no restrictions
on the location of the buffer, so it can be a global or local variable, or
allocated with New() or GetMem().


PROCEDURE FOpen(Fn  : STRING;  { Name of file to open. }
		DBSize : Word; { Size of buffer. 512 bytes minimum. }
		VAR BufP);     { Disk buffer to use. }

  If successful:
    Sets RFerror to 0.

  If not successful:
    Sets RFerror to DOS error code if a DOS error occured,
    or error 12 (Invalid File Access Code) if the buffer size is 0.

NOTES:
  The SYSTEM unit FileMode variable is used as the DOS File Access Mode
  passed to DOS function $3D, to open the file.  Actually, the low 3 bits
  are set to zero, specifying Read-Only access, but the high 5 file
  sharing bits are passed.

TRAPS:
  If using a buffer allocated with New() or GetMem(), be sure to use the
  caret after it for the BufP parameter. Ie. RF.FOpen(Fn, BSize, BufP^);

Never call FOpen twice with the same RFobject variable without calling
FCLOSE first.

EXAMPLE:
VAR
  RF : RFobject;
  Buffer : Array[1..2048] of Char;
BEGIN
  System.FileMode := 0;
  RF.FOpen('HELLO.PAS', Sizeof(Buffer), Buffer);
  If RFerror = 0
  THEN Writeln('Success')
  ELSE Writeln('Error: ', i);
...

--------------------------------------------------------------------------
PROCEDURE RFobject.FClose  - When done with the file, it must be closed
			     with a call to FClose:

PROCEDURE FClose;

Closes previously opened RFrec.
Returns nothing.

This procedure attempts to identify whether the file has been previously
opened before it attempts to ask DOS to close it.  It does not attempt to
close the file if:

 a) RF.BSize = 0. PROCEDURE FOpen sets RF.BSize to 0 if DOS open failed.
or
 b) RF.Handle < 5, in which case it would be a standard DOS handle, which
    shouln't be closed.

TRAP: A problem that could occur with this scheme would be if (the file was
never even attempted to be opened by FOpen) AND (the handle = the handle of
a file that is currently opened somewhere else in the program).

----------------------------------------------------------------------
PROCEDURE RFobject.FReadLn

FReadLn - Reads a string of characters up to the next ^M, or
	  the physical end of file, whichever comes first.
	  ^Z is ignored if it occurs at the end of the file.
	  If a ^Z appears before the end of the file, it is passed
	  on to "S".

	  VAR "S", which receives the string, MUST be of TYPE STRING
	  or STRING[255].

	  The maximum length of the string returned to caller is 255
	  characters.  If more than 255 characters are passed in the
	  file before ^M or <EOF>, the remaining characters are
	  discarded.


PROCEDURE FReadLn(VAR S   : STRING); { String variable to read next line to. }

On success:
  Sets RFerror to 0.
  S = next string read from file RF.Handle.
On failure:
  Sets RFerror to DOS error code,
  or $FFFF if End of File

Works like a Turbo Pascal Readln(F, S); except:
    (1) It works only with disk files.
    (2) Only reads type STRING. ie. not integers, words, or any other type.
    (3) It is much faster.
    (4) Doesn't stop when a ^Z is encountered before end of file.  If a ^Z
	is encountered AT the end of file, it is stripped.  Any ^Z's
	encountered before the physical end of the file are passed on
	to the string.
    (5) RFerror is set to $FFFF after calling this if the physical
	end of file is reached.  The value of "S" is invalid when the
	$FFFF end of file result is set.

----------------------------------------------------------------------
PROCEDURE RFobject.FRead - Reads the next character from the file:

PROCEDURE FRead(VAR Ch  : Char);  { Char variable to read next line to. }

Works the same as FReadLn but returns one character instead of a string.
All characters are passed on to Ch except ^Z if it occurs at end of file.
Any ^Z found before the physical end of file is passed on to Ch.

If successful:
  Sets RFerror to 0.
  Ch = next character in the file.

If failed:
  Sets RFerror to either DOS error code,
  or $FFFF if physical End of File

----------------------------------------------------------------------
Function RFobject.FFilePos - Returns current file position for use with FSeek.

FUNCTION FFilePos : LongInt;

Returns current file position. RF must have been previously opened.
If FFilePos is called before FOpen is called successfully, the results
will be meaningless.

----------------------------------------------------------------------
PROCEDURE RFobject.FSeek - Seeks to position FPo in previously opened RF.

PROCEDURE FSeek(FPo : LongInt) : Word;

If successful,
  RFerror is set to 0.

If failed,
  RFerror is set to DOS error code.

To Reset the file, call RFSeek with FPo := 0.  Ie. FSeek(0);

On a normal ^M^J ascii file, FFilePos will most often return the position of
the ^J after a call to FReadLn.  Because FReadLn strips leading ^J's, this
shouldn't be a problem.  But, bear that in mind if using the FFilePos
results for your own untyped file routines.


(****************************************************************************)

IMPLEMENTATION
USES
    {$IFNDEF NOTNEN}
    UERROR;
    {$ELSE}
    KERROR;
    {$ENDIF}

    {$L RLINE.OBJ}
    PROCEDURE RFobject.FOpen(Fn             : STRING;
                             DBSize         : WORD;
    VAR BufP); EXTERNAL;
    PROCEDURE RFobject.FClose; EXTERNAL;
    PROCEDURE RFobject.FReadLn(VAR S : STRING); EXTERNAL;
    PROCEDURE RFobject.FRead(VAR Ch : CHAR); EXTERNAL;
    PROCEDURE RFobject.FSeek(FPo : LONGINT); EXTERNAL;
    FUNCTION RFobject.FFilePos : LONGINT; EXTERNAL;

    { RFEXTENDED --------------------------------------------------------------}

    CONSTRUCTOR RFextended.Init(Fn             : STRING; { Name of file to open. }
                                DBSize         : WORD; { Size of buffer. }
                                VAR BufP); { Address of disk buffer }
    BEGIN
        {$IFNDEF Windows}
        FileName := FExpand(Fn);
        {$ELSE}
        FileName := Fn;
        {$ENDIF}
        FILEMODE := $40;
        FOpen(Fn, DBSize, BufP);
        FILEMODE := $2;
    END;

    (*********************)

    FUNCTION RFextended.FILESIZE : LONGINT;
    VAR
        {$IFNDEF Windows}
        R              : Registers;
        {$ELSE}
        R : TRegisters;
        {$ENDIF}
        FPos           : LONGINT;
        Res            : LONGINT;
        F              : INTEGER;
    LABEL
        ExitPoint;
    BEGIN
        FPos := FFilePos;         { save current file position }
        F := _Handle;
        WITH R DO BEGIN
            {$IFDEF Windows}
            asm
                mov     ax,4202h
                mov     bx,F
                xor     cx,cx
                mov     dx,cx
                int     21h
                jc      ExitPoint
                mov     word ptr Res,ax
                mov     word ptr Res+2,dx
            end;
            {$ELSE}
            ax := $4202;
            BX := _Handle;
            Cx := 0;
            DX := 0;
            msdos(R);
            IF Flags AND fcarry <> 0
            THEN RFerror := ax
            ELSE Res := (LONGINT(DX) SHL 16) OR ax;
            {$ENDIF}
        END;
        FILESIZE := Res;
        _TotBytesInBuf := 0;      { Force FSeek to move file pointer. }
        FSeek(FPos);              { restore current file position }
ExitPoint:
    END;

    (*********************)
(*
    FUNCTION RFextended.RFerrorString : STRING;
    BEGIN
        IF RFerror <> $FFFF THEN
            RFerrorString := ErrorMessage(RFerror)
        ELSE
            RFerrorString := 'End Of File.'; { special EOF number, unique to FRead and FReadln }
    END;
*)
    (*********************)

    FUNCTION RFextended.RFerrorString : STRING;
        { Converts RFerror to a string. }
    VAR
        S              : STRING[80];
    BEGIN
        CASE RFerror OF
            0 :
                S := 'Success';   { it's not an error. }
            100 :
                S := 'Attempted to read past End Of File.';
            101 :
                S := 'Disk write error.';
            102 :
                S := 'File not assigned.';
            103 :
                S := 'File not opened.';
            104 :
                S := 'File not open for input.';

            2 :
                S := 'File not found.';
            3 :
                S := 'Path not found.';
            4 :
                S := 'Too many files opened.';
            5 :
                S := 'File access denied.';
            6 :
                S := 'Invalid file handle.';
            $FFFF :
                S := 'End Of File.'; { special EOF number, unique to FRead and FReadln }
            200 :
                S := 'Divide by zero.  Buffersize = 0?';
            ELSE BEGIN
                STR(RFerror, S);
                S := 'IOerror ' + S;
            END;
        END;
        RFerrorString := S;
    END;

    (*********************)

    PROCEDURE RFextended.RESET;
    BEGIN
        FSeek(0);
    END;

    (*********************)

    DESTRUCTOR RFextended.Done;
    BEGIN
        FClose;
    END;

    { FILEOFLINES -------------------------------------------------------}

    CONSTRUCTOR FileOfLines.Init(Fn : STRING; SizeForBuffer : WORD);
    VAR
        F              : FILE;
        L, RamNeeded, FSize : LONGINT;
        BufNum         : WORD;
    BEGIN
        TBuf := NIL;
        BufRay := NIL;
        LastLineNum := 0;
        LastLine := '';
        TotalLines := 0;

        IF MAXAVAIL > SizeForBuffer { create the disk buffer }
        THEN
            BufSize := SizeForBuffer
        ELSE
            BufSize := MAXAVAIL;
        IF BufSize >= 256
        THEN
            GETMEM(TBuf, BufSize)
        ELSE
            FAIL;

        {$IFNDEF Windows}
        FileName := FExpand(Fn);  { open the file. }
        {$ELSE}
    FileName := Fn;
    {$ENDIF}
        FOpen(FileName, BufSize, TBuf^);
        IF RFerror = 0 THEN
            FSize := FILESIZE;

        IF RFerror <> 0 THEN
            EXIT;                 { Don't fail so RFerror can be polled in calling routine. }

        NBuffers := ((FSize DIV BufSize) + 1); { allocate ram for bufferarray }
        RamNeeded := NBuffers * SIZEOF(BufRec);
        IF (MAXAVAIL < RamNeeded) OR (NBuffers > MaxBufs) THEN BEGIN
            Done;
            FAIL;
        END;

        GETMEM(BufRay, RamNeeded);
        IF BufRay = NIL THEN
        BEGIN
            Done;
            FAIL;
        END;

        IF PermTBuf <> NIL THEN
        BEGIN
            TotalLines := PermTBuf^[1].Lno;
            MOVE(PermTBuf^[2], BufRay^, RamNeeded);
            RESET;
        END
        ELSE
        BEGIN
            { Index the file. }
            BufNum := 1;
            WITH BufRay^[1] DO BEGIN
                Lno := 1;
                FP := 0;
            END;

            FReadLn(LastLine);
            WHILE RFerror = 0 DO BEGIN
                INC(TotalLines);
                IF (_NBufs > BufNum) AND (BufNum < NBuffers) THEN BEGIN
                    INC(BufNum);
                    WITH BufRay^[BufNum] DO BEGIN
                        Lno := SUCC(TotalLines);
                        FP := FFilePos;
                    END;
                END;
                FReadLn(LastLine);
            END;

            IF RFerror = $FFFF THEN { make it to EOF with no problems? }
                RESET;
        END;
    END;

    (*********************)

    DESTRUCTOR FileOfLines.Done;
    BEGIN
        IF BufRay <> NIL THEN
            FREEMEM(BufRay, NBuffers * SIZEOF(BufRec));
        IF TBuf <> NIL THEN
            FREEMEM(TBuf, BufSize);
        BufRay := NIL;
        TBuf := NIL;
        FClose;
    END;

    (*********************)

    PROCEDURE FileOfLines.SeekLine(Row : LONGINT);
        { Seeks and reads row and puts in string LastLine }
    VAR
        I              : INTEGER;
    BEGIN
        IF Row > TotalLines THEN BEGIN
            RFerror := 100;       { Attempt to read past end of file. }
            EXIT;
        END;
        IF (Row <> LastLineNum + 1) THEN BEGIN
            I := 2;
            WHILE (I <= NBuffers) AND (BufRay^[I].Lno < Row) DO
                INC(I);
            DEC(I);
            WITH BufRay^[I] DO BEGIN
                FSeek(FP);
                IF RFerror = 0 THEN BEGIN
                    FReadLn(LastLine);
                    LastLineNum := Lno;
                END;
            END;
        END;
        WHILE (RFerror = 0) AND (LastLineNum < Row) DO BEGIN
            FReadLn(LastLine);
            INC(LastLineNum);
        END;
    END;


    (*********************)

    FUNCTION FileOfLines.ReturnBuffAdr(VAR NBuffs     : INTEGER;
                                       VAR TLS        : LONGINT) : PBufferArray;
        { returns Local Info to Main Pgm }
    BEGIN
        NBuffs := NBuffers;
        ReturnBuffAdr := BufRay;
        TLS := TotalLines;
    END;


END.
(*********************)
(*********************)
