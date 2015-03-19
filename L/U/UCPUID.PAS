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
{$A-,R-,S-,F+,O-}   { Hangs machine if overlayed }

Unit UCPUID;   { Get CPU information }

interface

Uses Dos, OpCrt, OpDos;

Type
  cpu_info_t = record
    cpu_type : byte;
    MSW : word;
    GDT : array[1..6] of byte;
    IDT : array[1..6] of byte;
    intflag : boolean;
    ndp_type : byte;
    ndp_cw : word;
    weitek: byte;
    test_type: char
  end;

  CPUInfoRec = Record
      Cpu     : String[5];
      Ndp     : String[5];
      CpuType : String[25];
      Ram     : word;        { Total RAM in K }
      Avail   : LongInt;
      EMSMax  : LongInt;
      EMSAvail: LongInt;
      XMSMax  : LongInt;
      XMSAvail: LongInt;
      XMSVers : Word;
      XMMVers : Word;
    end;

  procedure GetCPUInfo(var Info: CPUInfoRec);

implementation

var
  Cpu_info : Cpu_info_t;
  Regs: Registers;

{$L InfoPlus.obj}

  procedure CPUID(var a: cpu_info_t); external;

  function diskread(drive: byte; starting_sector: longint;
    number_of_sectors: word; var buffer): word; external;

  procedure longcall(addr: longint; var regs: registers); external;

  function ATIinfo(data_in: byte; register: word): byte; external;

  procedure AltIntr(intno: byte; var regs: registers); external;

  procedure AltMsDos(var regs: registers); external;

  function CirrusCK: byte; external;

  function CTICK: byte; external;

  function TsengCK: byte; external;

  function ZyMOSCK: byte; external;

  function nocarry : boolean;
    begin
    nocarry:=regs.flags and fcarry = $0000
    end; {nocarry}

  procedure GetCPUInfo(var Info: CPUInfoRec);
    var
      Xword1 : word;
      XByte  : byte;
      XLong  : LongInt;
    begin
      FillChar(Info, SizeOf(CpuInforec), 0);
      with Info do
        begin

          { Processor Type identification }

          cpu_info.test_type:='C';
          CPUID(cpu_info);
          with cpu_info do
            begin
              case cpu_type of
                $00 : CPU := '8088';
                $01 : CPU := '8086';
                $02 : CPU := 'V20';
                $03 : CPU := 'V30';
                $04 : CPU := '80188';
                $05 : CPU := '80186';
                $06 : CPU := '80286';
                $07 : CPU := '80386';
                $08 : CPU := '80486'
                else
                  CPU := '?????';
                end;

              Cpu_Info.test_type := 'N';
              CPUID(cpu_info);
              case Cpu_Info.ndp_type of
                $00 : NDP := 'none';
                $01 : NDP := '8087';
                $02 : NDP := '80287';
                $03 : NDP := '80387'
              else
                NDP := '';
              end {case}
            end;

          { CPU Type }

          with regs do
            begin
            AH:=$C0;
            intr($15, regs);
            if nocarry then
              begin
              xword1:=memw[ES : BX + 2];
              xbyte:=MemW[ES:BX + 4];
              case xword1 of
                $00FC:        if xbyte = 1 then
                                CPUType := 'PC-AT 2x9'
                              else
                                CPUType := 'Industrial AT 7531/2';
                $01FC:        case xbyte of
                                $00: CPUType := 'PC-AT 3x9 or clone';
                                $30: CPUType := 'Tandy 3000NL'
                              else
                                CPUType := 'Compaq 286/386 or clone';
                              end;
                $00FB:        if xbyte = 1 then
                                CPUType := 'PC-XT w/ Enh kbd, 3.5" support'
                              else
                                CPUType := 'PC-XT';
                $01FB:        CPUType := 'PC-XT/2';
                $02FC:        CPUType := 'PC-XT/286';
                $00F9:        CPUType := 'PC-Convertible';
                $00FA:        CPUType := 'PS/2 Model 30';
                $01FA:        CPUType := 'PS/2 Model 25';
                $09FC:        CPUType := 'PS/2 Model 30-286';
                $04FC:        if xbyte = 3 then
                                CPUType := 'PS/2 Model 50Z'
                              else
                                CPUType := 'PS/2 Model 50';
                $05FC:        CPUType := 'PS/2 Model 60';
                $04F8, $09F8: CPUType := 'PS/2 Model 70';
                $0CF8:        CPUType := 'PS/2 Model 55SX';
                $1BF8:        CPUType := 'PS2 Model 70-486';
                $00F8:        CPUType := 'PS/2 Model 80 16MHz';
                $01F8:        CPUType := 'PS/2 Model 80 20MHz';
                $06FC:        CPUType := '7552 Gearbox';
                $81FC:        CPUType := 'AT clone with Phoenix 386 BIOS';
              else
                CPUType := 'machine Unknown';
              end; {case}
            end;

          With Regs do
            begin
              Intr($12,Regs);     { BIOS Ram check }
              Ram := Regs.AX;
              Avail := MaxAvail;
            end;

          end;
          { Extended memory checks }

          with regs do
            begin
            AX:=$4300;
            Intr($2F, regs);
            if AL <> $80 then
              XMSMax := 0
            else
              begin
              AX:=$4310;
              Intr($2F, regs);
              xlong:=longint(ES) shl 16 + BX;
              AX:=0;
              longcall(xlong, regs);
              if AX <> 0 then
                begin
                XMSVers := AX;
                XMMVers := BX;
                end;
              AX:=$0800;
              longcall(xlong, regs);
              if (AX <> 0) or ((AX = 0) and ((BL = 0) or (BL = $A0))) then
                begin
                XMSMax := DX;
                XMSAvail := AX;
                end;
              end;
            end;

        end;  { With INFO }
    end; { Procedure }

End.
