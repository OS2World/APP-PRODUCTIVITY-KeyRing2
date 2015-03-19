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
{$O+,F+}

Unit UNetNode;   { Returns this workstations physical node address }

interface

uses
  Dos, OpString, Netware, NWIpxSpx;

type
  NodeString   = String[12];
  ServerString = String[48];

  function WorkstationNodeString: NodeString;
  function ServerNameString: ServerString;

  procedure GetNodeAddress(var WSID : PhysicalNodeAddress);
  function NodeAddressString(WSID: PhysicalNodeAddress): NodeString;

implementation

  procedure GetNodeAddress(var WSID : PhysicalNodeAddress);
  Var
    Internet : IPXAddress;
  Begin
    GetInternetAddress(GetConnNo,InterNet);
    WSID := InterNet.Node;
  end;

  function NodeAddressString(WSID: PhysicalNodeAddress): NodeString;
  var
    S: NodeString;
    I: integer;
    Logged : boolean;
  begin
    if not NetwareLoaded(Logged) then
      begin
        NodeAddressString := '0';
      end;
    S := '';
    for I := 1 to 6 do
      S := S + HexB(WSID[I]);
    NodeAddressString := S;
  end;

  function WorkstationNodeString: NodeString;
  var
    ID : PhysicalNodeAddress;
  begin
    GetNodeAddress(ID);
    WorkStationNodeString := NodeAddressString(ID);
  end;

  function ServerNameString: ServerString;
  var
    Info : ServerInformation;
    I    : integer;
    S    : ServerString;
    Logged : boolean;
  begin
    if not NetwareLoaded(Logged) then
      begin
        ServerNameString := '*Local*';
      end;
    GetServerInfo(Info);
    S := '';
    for i := 1 to 48 do
      S := S + Info.ServName[I];
    ServerNameString := Trim(S);
  end;

End.
