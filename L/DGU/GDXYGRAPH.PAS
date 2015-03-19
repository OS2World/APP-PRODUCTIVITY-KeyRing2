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
* Version   Date        Time    Programmer   Description
* 1.0       1  Feb 2003 2131    KMcCoy       virgin
* 1.1       20 Feb 2003 1728    KMcCoy       Improved scaling aesthetics
* ~log~
*
*
* ~notes~
* Description
* -----------
* Generic XY Graph object using GD Library
*
*
* ~notesend~
*
***************************************************************************

}
{$A+,B-,D+,E+,F+,G+,I+,L+,N+,O+,P+,Q+,R+,S+,T-,V-,X+,Y+}

UNIT GDXYGRAPH;

INTERFACE
USES
    CLASSES,
    GD,
    GDGRAPH;
TYPE

    PXYGraph          = ^TXYGraph;

    // XY Graph object
    TXYGraph         = CLASS(TGDGraph)
                         MySelf         : TXYGraph;

                         CONSTRUCTOR Create(FullExtent : TExtentRange); // i.e. 640x480
                         DESTRUCTOR Destroy; override;
                         PROCEDURE RenderGraph;

                         PRIVATE

                         PROCEDURE PlotLine(X, Y : DOUBLE; Color : LONGINT);
                         FUNCTION GetXScaleWidth  : LONGINT;
                         FUNCTION GetYScaleHeight : LONGINT;
                     END;

IMPLEMENTATION
USES
    Math,
    SysUtils,
    VPUTILS;

CONST
    LEADING = 1.1; // 10% of height used as leading between lines of text

    {------------}

    {instantiate a XY plotter object}
    CONSTRUCTOR TXYGraph.Create(FullExtent : TExtentRange); // i.e. 640x480
    BEGIN
        INHERITED Create(FullExtent);
        MySelf := Self;
    END;

    {------------}

    DESTRUCTOR TXYGraph.Destroy;
    BEGIN
        inherited Destroy;
    END;

    {------------}

    PROCEDURE TXYGraph.PlotLine(X, Y : DOUBLE; Color : LONGINT);
    VAR
        Pt : TPoint;
    BEGIN
        {$R-}
        // this could use some work in the case of clipped data
        IF Virgin THEN
            TXYGraph.MoveTo(X, Y)
        ELSE BEGIN
            TranslateXY(X, Y, Pt);
            gdImageLine(MyIm, MyCP.X, MyCP.Y, Pt.X, Pt.Y, Color);
            MyCP := Pt;
        END;

        {$R+}
        Virgin := FALSE;
    END;

    {------------}

    // draw graph in memory
    PROCEDURE TXYGraph.RenderGraph;
    VAR
        X,
        Y              : DOUBLE;
        ItemIndex      : LONGINT;
        XY             : TPlotCoord;
        Ch             : TPlotChannel;
        AllDone        : BOOLEAN;
        F              : pFile;
        MaxXLabelWidth,
        MaxYLabelHeight,
        Black,
        White,
        Red,
        Green,
        Blue : LONGINT;
        BRect : TBoundingRect;
        Strg : STRING;
    BEGIN
        INHERITED RenderGraph; // calc viewports & autoscale

        Draw3dPanel;

        DrawTextRegions;

        DrawScales;

        {now plot the data in each channel}
        FOR Ch := LOW(Ch) TO HIGH(Ch) DO BEGIN
            ItemIndex := 0;
            {plot each marker/cursor}

            IF MyData[Ch].DL = NIL THEN
                CONTINUE;

            Virgin := TRUE;

            FOR ItemIndex := 0 to MyData[Ch].DL.Count-1 DO BEGIN
                TPlotPoint(MyData[Ch].DL.Items[ItemIndex]).GetVal(XY);
                PlotLine(XY.X, XY.Y, MyData[Ch].Color);
            END;
        END;

        DrawMarkers;
    END;

    {------------}

    FUNCTION TXYGraph.GetXScaleWidth  : LONGINT;
    VAR
        Strg : STRING;
        Ch   : TPlotChannel;
        T,
        W,
        I : LONGINT;
        XY : TPlotCoord;
        PP : TPlotPoint;
        BRect          : TBoundingRect;
    BEGIN
        W := 0;
        FOR Ch := LOW(Ch) TO HIGH(Ch) DO BEGIN
            IF MyData[Ch].DL = NIL THEN
                CONTINUE;

            FOR I := 0 to MyData[Ch].DL.Count-1 DO BEGIN
                TPlotPoint(MyData[Ch].DL.Items[I]).GetVal(XY);
                Strg := Format(XScaleFormat, [XY.X]) + #0;
                gdImageStringFT(NIL, @BRect, MyGridColor, MyLabelFont, MyLabelPointSize, 0.0, 10, 10, @Strg[1]);
                T := BRect.URX - BRect.ULY;
                IF T > W THEN
                    W := T;
            END;
        END;
        Result := W;
    END;

    {------------}

    FUNCTION TXYGraph.GetYScaleHeight : LONGINT;
    BEGIN
        Result := CalcStringHeight(MyLabelFont, MyLabelPointSize, 0.0, 'H');
    END;

    {------------}

END.

    {------------}
    {------------}
