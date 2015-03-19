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
* Interface for BGI256
*
*
* ~notesend~
* ~nokeywords~
*
****************************************************************************
}
{$A+,B-,E+,F-,G+,I+,N+,O+,P-,Q+,R+,S+,T-,V-,X+,Y+}
UNIT CRTGRF;

INTERFACE
USES
    Dos;

CONST
    Mode200        = 0;           {320x200x256}
    Mode400        = 1;           {640x400x256}
    Mode480        = 2;           {640x480x256}
    Mode600        = 3;           {800x600x256}
    Mode768        = 4;           {1024x768x256}
    Mode1024       = 5;           {1280x1024x256}

FUNCTION BGI256AutoDetect : INTEGER;
FUNCTION InitBGI256(BGIPath : PathStr) : INTEGER;
    {$IFDEF VirtualPascal}
FUNCTION  installuserdriver(P:PathStr; Ptr:POINTER):WORD;
{$ENDIF}
IMPLEMENTATION

USES
    Graph,
    OpString;

    {-------------}

    FUNCTION BGI256AutoDetect : INTEGER;
    BEGIN
        BGI256AutoDetect := 127;  {return max mode if good}
    END;

    {-------------}

    FUNCTION InitBGI256(BGIPath : PathStr) : INTEGER;
    BEGIN
        {$IFNDEF VirtualPascal}
        InitBGI256 := InstallUserDriver(AddBackSlash(BGIPath) + 'BGI256', @BGI256AutoDetect);
        {$ELSE}
        InitBGI256 := 0;
        {$ENDIF}
    END;

    {-------------}

    {$IFDEF VirtualPascal}
    FUNCTION  installuserdriver(P:PathStr; Ptr:POINTER):WORD;
    begin
         InStallUserDriver := 0;
    end;
    {$ENDIF}

    {-------------}
END.
    {-------------}
    {-------------}
