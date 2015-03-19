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
* Checksum unit to calc EXE checksum;  This unit needs to be the last one
* in the map file (highest address).  Probably won't work with overlays.
*
* ~notesend~
* ~nokeywords~
*
****************************************************************************

}
{$A+,B-,D+,E+,F+,G+,I+,L+,N+,O-,P-,Q+,R+,S+,T-,V-,X+,Y+}
{$M 16384,0,655360}
UNIT SECHKSUM;
    {$I OPDEFINE.INC}
    {$D+,L+,X+}

INTERFACE
CONST
    FingerPrint    = #$A7 + #$B3 + #$22 + #$00 + #$FC + #$D5 + #$17 + #$11 + #$BB;
CONST
    {a search marker in the exe to tag the MyCRC location}
    MyCRCID        : STRING[9] = FingerPrint;
    MyCRC          : LONGINT = 0;

FUNCTION CalcCheckSum : LONGINT;

IMPLEMENTATION
USES
    OpClone;

TYPE
    OS             = RECORD
                         O,
                         S              : WORD;
                     END;


CONST
    Crc32Table     : ARRAY[0..255] OF LONGINT =
    (
        $00000000, $77073096, $ee0e612c, $990951ba, $076dc419, $706af48f, $e963a535,
        $9e6495a3, $0edb8832, $79dcb8a4, $e0d5e91e, $97d2d988, $09b64c2b, $7eb17cbd,
        $e7b82d07, $90bf1d91, $1db71064, $6ab020f2, $f3b97148, $84be41de, $1adad47d,
        $6ddde4eb, $f4d4b551, $83d385c7, $136c9856, $646ba8c0, $fd62f97a, $8a65c9ec,
        $14015c4f, $63066cd9, $fa0f3d63, $8d080df5, $3b6e20c8, $4c69105e, $d56041e4,
        $a2677172, $3c03e4d1, $4b04d447, $d20d85fd, $a50ab56b, $35b5a8fa, $42b2986c,
        $dbbbc9d6, $acbcf940, $32d86ce3, $45df5c75, $dcd60dcf, $abd13d59, $26d930ac,
        $51de003a, $c8d75180, $bfd06116, $21b4f4b5, $56b3c423, $cfba9599, $b8bda50f,
        $2802b89e, $5f058808, $c60cd9b2, $b10be924, $2f6f7c87, $58684c11, $c1611dab,
        $b6662d3d, $76dc4190, $01db7106, $98d220bc, $efd5102a, $71b18589, $06b6b51f,
        $9fbfe4a5, $e8b8d433, $7807c9a2, $0f00f934, $9609a88e, $e10e9818, $7f6a0dbb,
        $086d3d2d, $91646c97, $e6635c01, $6b6b51f4, $1c6c6162, $856530d8, $f262004e,
        $6c0695ed, $1b01a57b, $8208f4c1, $f50fc457, $65b0d9c6, $12b7e950, $8bbeb8ea,
        $fcb9887c, $62dd1ddf, $15da2d49, $8cd37cf3, $fbd44c65, $4db26158, $3ab551ce,
        $a3bc0074, $d4bb30e2, $4adfa541, $3dd895d7, $a4d1c46d, $d3d6f4fb, $4369e96a,
        $346ed9fc, $ad678846, $da60b8d0, $44042d73, $33031de5, $aa0a4c5f, $dd0d7cc9,
        $5005713c, $270241aa, $be0b1010, $c90c2086, $5768b525, $206f85b3, $b966d409,
        $ce61e49f, $5edef90e, $29d9c998, $b0d09822, $c7d7a8b4, $59b33d17, $2eb40d81,
        $b7bd5c3b, $c0ba6cad, $edb88320, $9abfb3b6, $03b6e20c, $74b1d29a, $ead54739,
        $9dd277af, $04db2615, $73dc1683, $e3630b12, $94643b84, $0d6d6a3e, $7a6a5aa8,
        $e40ecf0b, $9309ff9d, $0a00ae27, $7d079eb1, $f00f9344, $8708a3d2, $1e01f268,
        $6906c2fe, $f762575d, $806567cb, $196c3671, $6e6b06e7, $fed41b76, $89d32be0,
        $10da7a5a, $67dd4acc, $f9b9df6f, $8ebeeff9, $17b7be43, $60b08ed5, $d6d6a3e8,
        $a1d1937e, $38d8c2c4, $4fdff252, $d1bb67f1, $a6bc5767, $3fb506dd, $48b2364b,
        $d80d2bda, $af0a1b4c, $36034af6, $41047a60, $df60efc3, $a867df55, $316e8eef,
        $4669be79, $cb61b38c, $bc66831a, $256fd2a0, $5268e236, $cc0c7795, $bb0b4703,
        $220216b9, $5505262f, $c5ba3bbe, $b2bd0b28, $2bb45a92, $5cb36a04, $c2d7ffa7,
        $b5d0cf31, $2cd99e8b, $5bdeae1d, $9b64c2b0, $ec63f226, $756aa39c, $026d930a,
        $9c0906a9, $eb0e363f, $72076785, $05005713, $95bf4a82, $e2b87a14, $7bb12bae,
        $0cb61b38, $92d28e9b, $e5d5be0d, $7cdcefb7, $0bdbdf21, $86d3d2d4, $f1d4e242,
        $68ddb3f8, $1fda836e, $81be16cd, $f6b9265b, $6fb077e1, $18b74777, $88085ae6,
        $ff0f6a70, $66063bca, $11010b5c, $8f659eff, $f862ae69, $616bffd3, $166ccf45,
        $a00ae278, $d70dd2ee, $4e048354, $3903b3c2, $a7672661, $d06016f7, $4969474d,
        $3e6e77db, $aed16a4a, $d9d65adc, $40df0b66, $37d83bf0, $a9bcae53, $debb9ec5,
        $47b2cf7f, $30b5ffe9, $bdbdf21c, $cabac28a, $53b39330, $24b4a3a6, $bad03605,
        $cdd70693, $54de5729, $23d967bf, $b3667a2e, $c4614ab8, $5d681b02, $2a6f2b94,
        $b40bbe37, $c30c8ea1, $5a05df1b, $2d02ef8d
        );

VAR
    Crc32TableOfs  : WORD;

    (****************************)

    FUNCTION UpdateCRC32(CurByte : BYTE; CurCrc : LONGINT) : LONGINT;
        {-Returns an updated crc32}

  (* Model for inline code below
  UpdateCrc32 := Crc32Table[Byte(CurCrc xor LongInt(CurByte))] xor
                 ((CurCrc shr 8) and $00FFFFFF);
  *)

    INLINE(
        {;Get args -- DX:BX = CurCrc, CX = CurByte;}
        $5B /                     {        POP     BX}
        $5A /                     {        POP     DX}
        $59 /                     {        POP     CX}
        $52 /                     {        PUSH    DX}
        $53 /                     {        PUSH    BX      ;Save original CurCrc}
        {;CX:AX := Get Crc32Table[CurCrc xor CurByte];}
        $31 / $CB /               {        XOR     BX,CX   ;DX:BX = CurCrc xor CurByte}
        $30 / $FF /               {        XOR     BH,BH   ;Byte(DX:BX)}
        $D1 / $E3 /               {        SHL     BX,1    ;LongInt index}
        $D1 / $E3 /               {        SHL     BX,1}
        $03 / $1E / >Crc32TableOfs / {        ADD     BX,[>Crc32TableOfs]}
        $8B / $07 /               {        MOV     AX,[BX]}
        $8B / $4F / $02 /         {        MOV     CX,[BX+2]}
        {;DX:BX := (CurCrc shr 8) and $00FFFFFF;}
        $5B /                     {        POP     BX      ;Get original CurCrc}
        $5A /                     {        POP     DX}
        $51 /                     {        PUSH    CX      ;Save CX}
        $B9 / $08 / $00 /         {        MOV     CX,8    ;Shift 8 bits}
        $D1 / $EA /               {C1:     SHR     DX,1    ;Hi reg into carry}
        $D1 / $DB /               {        RCR     BX,1    ;Carry into lo reg}
        $E2 / $FA /               {        LOOP    C1      ; for 8 bits}
        $81 / $E2 / $FF / $00 /   {        AND     DX,$00FF}
        {;DX:AX := ES:AX xor DX:BX (sets function result)}
        $59 /                     {        POP     CX}
        $31 / $D8 /               {        XOR     AX,BX}
        $89 / $CB /               {        MOV     BX,CX}
        $31 / $DA);               {        XOR     DX,BX}

    (****************************)

    {$IFDEF StonyBrook}           {!!.13}
    function Normalized(P : Pointer) : Pointer [ALTERS(AX,BX,CX,DX)];      {!!.13}
    {$ELSE}                                                                {!!.13}
    FUNCTION Normalized(P : POINTER) : POINTER;
        {$ENDIF}                  {!!.13}
        {-Return P as a normalized pointer}
    INLINE(
        $58 /                     {pop ax    ;pop offset into AX}
        $5A /                     {pop dx    ;pop segment into DX}
        $89 / $C3 /               {mov bx,ax ;BX = Ofs(P^)}
        $B1 / $04 /               {mov cl,4  ;CL = 4}
        $D3 / $EB /               {shr bx,cl ;BX = Ofs(P^) div 16}
        $01 / $DA /               {add dx,bx ;add BX to segment}
        $25 / $0F / $00);         {and ax,$F ;mask out unwanted bits in offset}

    (****************************)

    FUNCTION PtrToLong(P : POINTER) : LONGINT;
        {-Convert pointer, in range $0:$0 to $FFFF:$000F, to LongInt}
    BEGIN
        PtrToLong := (LONGINT(OS(P).S) SHL 4) + OS(P).O;
    END;

    (****************************)

    FUNCTION LongToPtr(L : LONGINT) : POINTER;
        {-Return LongInt L as a normalized pointer}
    BEGIN
        LongToPtr := PTR(WORD(L SHR 4), WORD(L AND $F));
    END;

    (****************************)

TYPE
    BlockP         = ^BlockT;
    BlockT         = ARRAY[1..$FFFF] OF BYTE;

    KCloneP        = ^KClone;
    KClone         = OBJECT(Cloner)
                         CONSTRUCTOR Init;
                         DESTRUCTOR Done; VIRTUAL;
                         FUNCTION GetCRC : LONGINT;

                     PRIVATE

                         Bp             : BlockP;
                         StopHere       : LONGINT;
                     END;

    (****************************)

    FUNCTION KClone.GetCRC : LONGINT;
    VAR
        I,
        BytesChecked,
        TCRC           : LONGINT;
        F              : FILE;
        Res            : WORD;
    BEGIN
        GetCRC := 0;
        ASSIGN(F, PARAMSTR(0));
        {$I-}
        RESET(F, 1);
        Res := IORESULT;
        IF Res <> 0 THEN
            EXIT;
        {$I+}
        {do a little crc check to thwart amateur hackers}
        TCRC := $FFFFFFFF;
        BytesChecked := 0;
        REPEAT
            BLOCKREAD(F, Bp^, SIZEOF(BlockT), Res);
            FOR I := 1 TO Res DO BEGIN
                IF BytesChecked = StopHere THEN
                    INC(I, SIZEOF(LONGINT));
                TCRC := UpdateCRC32(Bp^[I], TCRC);
                INC(BytesChecked);
            END;
        UNTIL Res <> SIZEOF(BlockT);
        CLOSE(F);
        {self-Stamp the CRC checksum into the EXE, first thing after compile}
        LoadDefaults(StopHere, MyCRC, SIZEOF(LONGINT));
        IF MyCRC = 0 THEN BEGIN
            MyCRC := TCRC;
            StoreDefaults(StopHere, MyCRC, SIZEOF(LONGINT));
        END;

        GetCRC := TCRC;
    END;

    (****************************)

    CONSTRUCTOR KClone.Init;
    BEGIN
        NEW(Bp);
        IF Bp = NIL THEN
            FAIL;
        IF NOT INHERITED InitAndFind(PARAMSTR(0), UpdateNone, MyCRCID[1], LENGTH(MyCRCID)) THEN
            FAIL;

        StopHere := GetPos + LENGTH(MyCRCID);

    END;

    (****************************)

    DESTRUCTOR KClone.Done;
    BEGIN
        DISPOSE(Bp);
        INHERITED Done;
    END;

    (****************************)

    {Function to calculate the CRC checksum of the EXE file}
    FUNCTION CalcCheckSum : LONGINT;
    VAR
        Cp             : KCloneP;
    BEGIN
        CalcCheckSum := 0;
        NEW(Cp, Init);
        IF Cp = NIL THEN
            EXIT;
        CalcCheckSum := Cp^.GetCRC;
        DISPOSE(Cp, Done);
    END;

    (****************************)

BEGIN
    {$IFNDEF UsePModeDLL}
    Crc32TableOfs := OFS(Crc32Table);
    {$ENDIF}
END.
