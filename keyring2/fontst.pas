program Fontst;

  Uses
    Os2Base,
    Os2Def,
    Os2PmApi;

  {$PMTYPE PM}       // Presentation Manager program

  var
    Ps    : Hps;          // presentation space handle
    CFonts : Long;         // fonts not returned
    LTemp  : Long;         // font count
    Pfm    : PFONTMETRICS; // metrics structure

  Begin
    lTemp := 0;
    // Determine the number of fonts.

    cFonts := GpiQueryFonts(Ps, qf_Private, 'Helv', lTemp,
                            sizeof(FONTMETRICS), nil);

    // Allocate space for the font metrics.

    DosAllocMem(pointer(pfm),(cFonts*sizeof(FONTMETRICS)),
                PAG_COMMIT Or PAG_READ Or PAG_WRITE);

    // Retrieve the font metrics.

    cFonts := GpiQueryFonts(Ps, qf_Private, 'Helv', cFonts,
                            sizeof(FONTMETRICS), pfm);
  end.
