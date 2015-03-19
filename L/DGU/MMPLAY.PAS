{~Change:Added PF directive to stop the *#$!&*#& thing from munching the source code~}
{***************************************************************************
* Filename: mmplay.pas
* Version:  1.2
* Date:     04/08/98 @ 12:16:08
* Group:
* Release:
* ----------------------------
*
* Modifications
* -------------
*
* Version   Date     Time    Programmer   Description
*  1.0    01/06/98 11:11:08  K_McCoy
*  virgin
*
*  1.1    01/06/98 11:21:05  K_McCoy
*  added headers
*
*  1.2    04/08/98 12:16:08  K_McCoy
*
*
*
*
* ~notes~
* Description
* -----------
* Generic sound player for OS/2 VIO applications
* Requires installation of MMPM
* Not for PM programs!
*
* By Kevin G. McCoy, IDK, Inc.
* Released to public domain
*
* If you make noteworthy changes, please send them to:
* kgmccoy@idk-inc.com
*
* Things left to do:
*
* Add ability to queue up playlist and play them end-to-end in background.
* This requires some sort of background thread to handle notification messages
* from MMPM when a song ends.
*
****************************************************
*
*   Sample to show foreground playing of sound/music files
*   Hangs while sound plays - returns from PlayAllAndWait when
*   all music stops

    PROCEDURE DoItWait;
    VAR
        TSP            : TSoundPlayer;
    BEGIN
        TSP := TSoundPlayer.Create;
        // queue up 3 songs and play them sequentially in the foreground
        // you can queue up as many songs as you have memory for - zillions are possible
        TSP.AddSong('thx1.mid');
        TSP.AddSong('test.wav');
        TSP.AddSong('d:\soundfx\soundbites\herekity.wav');
        TSP.PlayAllAndWait;
        TSP.Destroy;
    END;

*
*   Sample to show background player that begins playing a song
*   and returns to calling context immediately. Screen updates
*   while playing.
*
    PROCEDURE DoitBG;
    VAR
        TSP            : TSoundPlayer;
    BEGIN
        TSP := TSoundPlayer.Create;
        // queue up 2 songs and play them sequentially in the background
        // if you hit the Enter key while the first is playing, the second one
        // will play a duet with the first :-)
        // This works with Wav and Midi - don't know if you can do 2 midis at a time
        TSP.AddSong('thx1.mid');
        TSP.AddSong('test.wav');
        TSP.PlayBackGround(0); // play the first song
        WHILE NOT KeyPressed DO
            WRITELN('1');
        ReadKey;
        TSP.PlayBackGround(1); // play the second song
        WHILE NOT KeyPressed DO
            WRITELN('2');
        TSP.Destroy;
    END;

* ~notesend~
* ~nokeywords~
*
****************************************************************************
}
{.F-}
UNIT MMPLAY;
INTERFACE

USES
    Classes,
    Os2Base,
    Os2Def,
    OS2MM;

TYPE

    {a song is any sort of audio file - WAV, MID, etc}
    TSong          = CLASS(TObject)
                         CONSTRUCTOR Create(Name : STRING);
                         DESTRUCTOR Destroy; override;
                     PUBLIC
                         MyName         : STRING;
                         MyAlias        : STRING[8];
                     END;

    {a list of songs to be played either sequential or random access}
    {foreground or background - even duets}
    TPlayList      = CLASS(TList)
                         CONSTRUCTOR Create;
                         DESTRUCTOR Destroy; override;
                         PROCEDURE AddSong(Name : STRING);
                         FUNCTION GetNthName(N : LONGINT) : STRING;
                         FUNCTION GetNthAlias(N : LONGINT) : STRING;
                     PRIVATE
                         PROCEDURE ClearList;
                     END;

    {the actual player object}
    TSoundPlayer   = CLASS(TObject)
                         CONSTRUCTOR Create;
                         DESTRUCTOR Destroy; override;
                         PROCEDURE AddSong(Name : STRING);
                         PROCEDURE PlayAndWait(N : LONGINT);
                         PROCEDURE PlayBackGround(N : LONGINT);
                         PROCEDURE PlayAllAndWait;
                         PROCEDURE PlayAllInBackGround;
                         PROCEDURE AbortPlay(N : LONGINT);
                         PROCEDURE AbortAll;
                         FUNCTION GetNthName(N : LONGINT) : STRING;

                     PRIVATE

                         MyAlias        : STRING;
                         retstring      : ARRAY[0..300] OF CHAR;
                         retsize        : LONGINT;
                         Handle         : HWND;
                         PlayList       : TPlayList;
                         OwnerPID       : Pid;
                         tidCntThread   : TID;
                         QHandle        : HQUEUE;
                         QueueName      : ARRAY[0..100] OF CHAR;

                         PROCEDURE SendString(Strg : PCHAR; userparm : ULONG);
                     END;

IMPLEMENTATION
USES
    sysutils;

    {---------------------}

    FUNCTION RandChar : STRING;
    BEGIN
        RandChar := CHAR(ORD('A') + RANDOM(26));
    END;

    {---------------------}

    FUNCTION RandString(Len : BYTE) : STRING;
    VAR
        I              : BYTE;
        Strg           : STRING;
    BEGIN
        Strg := '';
        FOR I := 1 TO Len DO
            Strg := Strg + RandChar;
        RandString := Strg;
    END;

    {---------------------}

    {create a new song instance}
    CONSTRUCTOR TSong.Create(Name : STRING);
    BEGIN
        INHERITED Create;
        MyName := Name;
        MyAlias := RandString(8);
    END;

    {---------------------}

    {destroy a song instance}
    DESTRUCTOR TSong.Destroy;
    BEGIN
        INHERITED Destroy;
    END;

    {---------------------}

    {create a playlist instance}
    CONSTRUCTOR TPlayList.Create;
    BEGIN
        INHERITED Create;
    END;

    {---------------------}

    {destroy a playlist instance}
    DESTRUCTOR TPlayList.Destroy;
    BEGIN
        ClearList;
        INHERITED Destroy;
    END;

    {---------------------}

    {add a song to the playlist}
    PROCEDURE TPlayList.AddSong(Name : STRING);
    VAR
        S              : TSong;
    BEGIN
        S := TSong.Create(Name);
        Add(S);
    END;

    {---------------------}

    {return the nth instance of a song in the playlist}
    FUNCTION TPlayList.GetNthName(N : LONGINT) : STRING;
    BEGIN
        Result := TSong(Items[N]).MyName;
    END;

    {---------------------}

    {for internal use - get the song alias name}
    FUNCTION TPlayList.GetNthAlias(N : LONGINT) : STRING;
    BEGIN
        Result := TSong(Items[N]).MyAlias;
    END;

    {---------------------}

    {empty the playlist}
    PROCEDURE TPlayList.ClearList;
    VAR
        I              : LONGINT;
    BEGIN
        FOR I := 0 TO Count - 1 DO BEGIN
            TSong(Items[I]).Destroy;
            Items[I] := NIL;
        END;
    END;

    {---------------------}

    {this needs work, especially in multithreaded apps with multiple TSoundPlayers flying in formation}
    FUNCTION QMon(qh : ULONG) : APIret; CDECL;
    VAR
        Rc             : APIret;
        Priority       : BYTE;
        RD             : REQUESTDATA;
        Msg,
        mp1,
        mp2            : ULONG;
        StrBuf         : ARRAY[0..256] OF CHAR;
    BEGIN
        REPEAT
            Result := DosReadQueue(HQUEUE(qh), RD, mp1, mp2, 0, 0, Priority, 0);
            CASE RD.Data OF
                MM_MCINOTIFY :
                    BEGIN
                    END;
                MM_MCIPASSDEVICE :
                    BEGIN
                        {
                        WRITELN(StrFmt(StrBuf, '   Device id=%d', [mp1]));
                        CASE mp2 OF
                            MCI_LOSING_USE :
                                WRITELN('   MCI_LOSING_USE:');
                            MCI_GAINING_USE :
                                WRITELN('   MCI_GAINING_USE:');
                            ELSE
                                WRITELN(StrFmt(StrBuf, '   mp2=%d', [mp2]));
                        END;
                        }
                    END;
                MM_MCIPOSITIONCHANGE :
                    BEGIN
                        {
                        WRITELN('   msg=MM_MCIPOSITIONCHANGE');
                        WRITELN(StrFmt(StrBuf, '   mp1=%d', [mp1]));
                        WRITELN(StrFmt(StrBuf, '   mp2=%d', [mp2]));
                        }
                    END;
                MM_MCICUEPOINT :
                    BEGIN
                        {
                        WRITELN('   msg=MM_MCICUEPOINT');
                        WRITELN(StrFmt(StrBuf, '   mp1=%d', [mp1]));
                        WRITELN(StrFmt(StrBuf, '   mp2=%d', [mp2]));
                        }
                    END;
                MM_MCIPLAYLISTMESSAGE :
                    BEGIN
                        {
                        WRITELN('   msg=MM_MCIPLAYLISTMESSAGE');
                        WRITELN(StrFmt(StrBuf, '   mp1=%d', [mp1]));
                        WRITELN(StrFmt(StrBuf, '   mp2=%d', [mp2]));
                        }
                    END;
                MM_MCIEVENT :
                    BEGIN
                        {
                        WRITELN('   msg=MM_MCIEVENT');
                        WRITELN(StrFmt(StrBuf, '   mp1=%d', [mp1]));
                        WRITELN(StrFmt(StrBuf, '   mp2=%d', [mp2]));
                        }
                    END;
                ELSE BEGIN
                    {
                    WRITELN(StrFmt(StrBuf, '   msg=%d', [RD.Data]));
                    WRITELN(StrFmt(StrBuf, '   mp1=%d', [mp1]));
                    WRITELN(StrFmt(StrBuf, '   mp2=%d', [mp2]));
                    }
                END;
            END;
        UNTIL FALSE;
    END;

    {---------------------}

    {create a soundplayer instance}
    CONSTRUCTOR TSoundPlayer.Create;
    BEGIN
        {$IFDEF DLL}
        MM_DLLInit;
        {$ENDIF}
        INHERITED Create;
        PlayList := TPlayList.Create;
        retsize := 300;
        OwnerPID := 0;
        QHandle := 0;

        {set up a unique named queue, in case we have multiple players}
        {going at the same time}
        StrFmt(QueueName, '\QUEUES\MUZAK\%s', [RandString(8)]);

        IF DosCreateQueue(QHandle, QUE_FIFO, QueueName) <> 0 THEN
            FAIL;

        IF DosOpenQueue(OwnerPID, QHandle, QueueName) <> 0 THEN
            FAIL;

        {create a thread to monitor progress of the songs}
        IF DosCreateThread(tidCntThread, QMon, QHandle, 0, 65536) <> 0 THEN
            FAIL;

    END;

    {------------}

    {public entry point to add a song to the player}
    PROCEDURE TSoundPlayer.AddSong(Name : STRING);
    VAR
        S              : TSong;
    BEGIN
        S := TSong.Create(Name);
        PlayList.Add(S);
    END;

    {------------}

    {returns the nth song name}
    FUNCTION TSoundPlayer.GetNthName(N : LONGINT) : STRING;
    BEGIN
        Result := TSong(PlayList.Items[N]).MyName;
    END;

    {------------}

    {shut down and boogie}
    DESTRUCTOR TSoundPlayer.Destroy;
    BEGIN
        DosCloseQueue(QHandle);
        DosKillThread(tidCntThread);
        PlayList.Destroy;
        INHERITED Destroy;
    END;

    {------------}

    {stop all songs from playing - leaves songs in list}
    PROCEDURE TSoundPlayer.AbortAll;
    VAR
        I              : LONGINT;
    BEGIN
        FOR I := 0 TO PlayList.Count - 1 DO
            AbortPlay(I);
    END;

    {------------}

    {play a song in foreground - hangs until song is over}
    PROCEDURE TSoundPlayer.PlayAndWait(N : LONGINT);
    VAR
        StrS           : ARRAY[0..300] OF CHAR;
        StrR           : PCHAR;
    BEGIN
        mciSendString(StrFmt(StrS, 'open %s alias %s wait', [PlayList.GetNthName(N), PlayList.GetNthAlias(N)]), StrR, 0, 0, 0);
        mciSendString(StrFmt(StrS, 'play %s wait', [PlayList.GetNthAlias(N)]), StrR, 0, 0, 0);
        mciSendString(StrFmt(StrS, 'close %s wait', [PlayList.GetNthAlias(N)]), StrR, 0, 0, 0);
    END;

    {------------}

    {play a song in the background - returns immediately}
    PROCEDURE TSoundPlayer.PlayBackGround(N : LONGINT);
    VAR
        StrS           : ARRAY[0..300] OF CHAR;
    BEGIN
        SendString(StrFmt(StrS, 'open %s shareable dosqueue wait alias %s', [PlayList.GetNthName(N), PlayList.GetNthAlias(N)]), 0);
        SendString(StrFmt(StrS, 'play %s notify', [PlayList.GetNthAlias(N)]), 0);
    END;

    {------------}

    {play all songs sequentially, hangs while playing}
    PROCEDURE TSoundPlayer.PlayAllAndWait;
    VAR
        I              : LONGINT;
    BEGIN
        FOR I := 0 TO PlayList.Count - 1 DO
            PlayAndWait(I);
    END;

    {------------}

    {play all songs sequentially in background - no hang}
    PROCEDURE TSoundPlayer.PlayAllInBackGround;
    BEGIN
        {launch player thread?}
    END;

    {------------}

    {stop playing the nth song}
    PROCEDURE TSoundPlayer.AbortPlay(N : LONGINT);
    VAR
        StrS           : ARRAY[0..300] OF CHAR;
    BEGIN
        SendString(StrFmt(StrS, 'close %s wait', [PlayList.GetNthAlias(N)]), 0);
    END;

    {------------}

    {send a string to os/2 multimedia api}
    PROCEDURE TSoundPlayer.SendString(Strg : PCHAR; userparm : ULONG);
    VAR
        Rc             : ULONG;
        Buf,
        ES             : ARRAY[0..100] OF CHAR;
        S              : PCHAR;
    BEGIN
        TRY
            Rc := mciSendString(Strg, retstring, retsize, QHandle, userparm);
            IF Rc <> 0 THEN BEGIN
                mciGetErrorString(Rc, ES, 100);
                WRITELN(ES);
                WRITELN(StrFmt(Buf, 'Error : (%s) rc=%d QHid=%d U=%d', [Strg, Rc, QHandle, userparm]));
            END;
        EXCEPT
            IF Rc <> 0 THEN BEGIN
                mciGetErrorString(Rc, ES, 100);
                WRITELN(ES);
                WRITELN(StrFmt(Buf, 'Error : (%s) rc=%d QHid=%d U=%d', [Strg, Rc, QHandle, userparm]));
            END;
        END;
    END;

    {---------------------}

END.
{.F+}

    {---------------------}
    {---------------------}

