program PaRAlleLJAzZ;

uses PJUnit,NewCrt,Crt,dos;

const
  maxarea = 255;

type
    WinREC = record
                   x1,y1,x2,y2 : Byte;       { window coordinates }
                   Col         : Byte;       { window colors }
             end;
    letters = set of char;

    Areatype = record x1,x2,y1,y2:word; end;

    SlideRec = record
                 on    :boolean;
                 dir   :byte;
                 fr    :word;
                 count :byte;
                 val   :byte;
               end;

var
   UMFName : String[12];        { filename }
   CurCh   : Byte;              { Current window }
   CurPlace: Byte;
   CurVol  : Byte;
   CurSno  : Byte;
   FAddr   : Word;              { first notes addr on screen }
   MAddr   : Word;
   MPos    : byte;

   FMeta   : Byte;              { first Meta win on screen }
   PlayOn  : boolean;           { is play-mode on }
   InsOn   : 0..2;              { which insert-mode? }
   HeapSt  : Pointer;           { heapstate in the start }
   key     : word;              { current key's scancode }
   in1,in2,in3,in4 : integer;       { dummy variables }
   MetaPos : Byte;              { current Meta Position }
   CurNote : Word;              { current note position }
   OrgPal  : array[0..15] of record R,G,B:byte; end; { original palette }
   step    : byte;              { current step }
   endo    : boolean;

 { Player Stuff }
   Pl_Note : array[0..maxoch] of word;
   Pl_Count: word;
   Pl_Order: array[0..maxoch] of byte;
   Pl2_count :word;
   Pl2_note: word;
   Pl2_place:word;
   snoff :array[0..8] of boolean;

   int1csave:pointer;

   bdval    :byte;              { value to $bd }
   bnkfile  :string[12];
   curpos   :byte;

   Sl       : array[0..8] of SLideREC;
   Dl       : array[0..8] of record on:boolean; val:byte; nt:word; end;
   DlCount  : byte;
 { Area Stuff }
   Area     :AreaType;
   AreaOn,AreaOn2   :boolean;
   CtrlS    :boolean;            { has ^s been pressed }
   Clipb    :array[0..maxch,0..maxarea] of NoteType;
   ClipbMax :record x,y:byte; end;

   SongChange:Boolean;
   lskey     :byte;
   LInsCol   :Byte;              { Last Instrument Color ( WrCmd ) }
   initialized :boolean;

label 1,2;
const
     EmptyArea : Areatype = (x1:0; x2:0; y1:0; y2:0);

     col_note = $05;
     col_META = $05;
     col_Addr = $02;
     col_UMF  = $05;
     col_Cmd  = $03;
     col_Cmd2 = $06;
     col_cur  = $20;
     col_ins  = $30;
     col_ent  = $50;
     col_area = $73;

     bplace   = 14;
     ver    = '1.0á';
     hexs   : array[0..15] of char =('0','1','2','3','4','5','6','7',
                                      '8','9','A','B','C','D','E','F');


     WinNum = 5;
     Win    : array[1..winnum] of WinREc =
                ((x1:0; y1:0; x2:79; y2:0; Col:$43),
                 (x1:5; y1:2; x2:16; y2:2; Col:col_UMF),
                 (x1:24;y1:2; x2:55; y2:2; Col:col_UMF),
                 (x1:63;y1:2; x2:64; y2:2; Col:col_UMF),
                 (x1:74; y1:2; x2:75;y2:2; Col:col_UMF));

     AWin   : WinREC =
                 (x1:2; y1:bplace+1; x2:5; y2:48; Col:col_Addr);


     NWin   : array[0..8] of WinREC =
                ((x1:7; y1:bplace+1; x2:13; y2:48; Col:col_note),
                 (x1:15; y1:bplace+1; x2:21; y2:48; Col:col_note),
                 (x1:23; y1:bplace+1; x2:29; y2:48; Col:col_note),
                 (x1:31; y1:bplace+1; x2:37; y2:48; Col:col_note),
                 (x1:39; y1:bplace+1; x2:45; y2:48; Col:col_note),
                 (x1:47; y1:bplace+1; x2:53; y2:48; Col:col_note),
                 (x1:55; y1:bplace+1; x2:61; y2:48; Col:col_note),
                 (x1:63; y1:bplace+1; x2:69; y2:48; Col:col_note),
                 (x1:71; y1:bplace+1; x2:77; y2:48; Col:col_note));

     MWin   : array[0..8] of winrec =
                ((x1:2; y1:4; x2:5; y2:bplace-1; Col:col_META),
                 (x1:7; y1:4; x2:10; y2:bplace-1; Col:col_META),
                 (x1:12; y1:4; x2:15; y2:bplace-1; Col:col_META),
                 (x1:17; y1:4; x2:20; y2:bplace-1; Col:col_META),
                 (x1:22; y1:4; x2:25; y2:bplace-1; Col:col_META),
                 (x1:27; y1:4; x2:30; y2:bplace-1; Col:col_META),
                 (x1:32; y1:4; x2:35; y2:bplace-1; Col:col_META),
                 (x1:37; y1:4; x2:40; y2:bplace-1; Col:col_META),
                 (x1:42; y1:4; x2:45; y2:bplace-1; Col:col_META));

     OWin   : array[1..5] of WinREC =
                ((x1:35; y1:22; x2:45; y2:29; col:$13),
                 (x1:30; y1:16; x2:54; y2:38; Col:$13),
                 (x1:29; y1:24; x2:51; y2:24; Col:$13),
                 (x1:18; y1:22; x2:62; y2:24; Col:$13),
                 (x1:2; y1:10; x2:77; y2:38; Col:$13));

     Freqs : array[1..16] of string[2] = ('C-','C#','D-','D#','E-','F-',
                                          'F#','G-','G#','A-','A#','B-',
                                          '?-','?#','?-','?#');

     MCNum = 12;
     MCmds : array[0..MCNum] of string[16] =
                   ('Sound Change','Tempo Change','Rythm On','Rythm Off',
                    'Attribute Change','Mod Vol Change','Car Vol Change',
                    'Note Slide Up','Note Slide Down','Slide To Note','','',
                    'Delay Note');
     wait_Non  = 'ùùù úúo';
     wait_Noff = 'ùùù ';
     wait_Norm = 'úúú úúo';

     MetaNum = 1;
     MetaName :array[1..metanum] of string[16] = ('Sound Change');

     MyPal : array [0..15] of record r,g,b:byte; end =
                   ((R:0; G:0; B:0),
                    (R:18; G:25; B:15),
                    (R:32; G:50; B:28),
                    (R:50; G:55; B:45),
                    (R:23; G:29; B:20),
                    (R:48; G:44; B:05),
                    (R:10; G:23; B:13),
                    (R:34; G:30; B:03),
                    (R:48; G:44; B:05),
                    (R:25; G:46; B:55),
                    (R:25; G:46; B:55),
                    (R:35; G:46; B:55),
                    (R:45; G:46; B:95),
                    (R:35; G:46; B:95),
                    (R:25; G:46; B:15),
                    (R:225; G:216; B:215));
function whex(des:word):string;
const str1:string[4] = '';
begin
     str1 := hexs[des and $0f] + str1;
     des := des shr 4;
     str1 := hexs[des and $0f] + str1;
     des := des shr 4;
     str1 := hexs[des and $0f] + str1;
     des := des shr 4;
     str1 := hexs[des and $0f] + str1;
     whex := str1;
end;

function bhex(des:byte):string;
const str1:string[2] = '';
begin
     str1 := hexs[des and $0f] + str1;
     des := des shr 4;
     str1 := hexs[des and $0f] + str1;
     bhex := str1;
end;

procedure CurHome;
begin
     TPos.x := 7;
     TPos.y := bplace+1;
     MPos   := 0;
     MAddr  := 0;
     CurCh  := 0;
     FMEta  := 0;
     FAddr  := 0;
end;

procedure HndErr;
const
  errs :array[0..13] of string[28] =
     (' ','File Not Found','Invalid File',
     'Unknown File Format','Bad life!','Weird Situation!','Bad Motherfucker!',
     'Hey, Take It Easy!','Old Jokes Strike Back!','Not An Error!',
     'Something done!','Cold Home!','Yeah, Your Song''s Groovy!','No shit!');
begin
     if ErrCode in [0..18] then
     WrXY(errs[ErrCode],2,49);
end;
procedure PlayHandler; Interrupt;
var fre,fre2,i1,i2,i3,i4,cm,cnote : word;
    slide :byte;
    dela :byte;
    TMEta :MetaPtr;

begin
     slide := 0;
     if (playon) then
     begin
      for i1 := 0 to 8 do
      begin
       if sl[i1].on then
       begin
         if sl[i1].count = 0 then
         begin
           if sl[i1].dir = 1 then inc(sl[i1].fr,sl[i1].val and $f)
           else dec(sl[i1].fr,sl[i1].val and $f);
           access($a0+i1,sl[i1].fr and $ff,bport);
           access($b0+i1,(sl[i1].fr shr 8) and 31+32,bport);
           sl[i1].count := sl[i1].val shr 4;
         end else dec(sl[i1].count);
       end;
       if Dl[i1].on then
         if Dl[i1].val = umf.tempo - Pl_Count then
         begin
           if channel[i1]^[Dl[i1].nt].Data and $80 = 0 then access($b0+i1,0,bport);
           fre:= NotFreqs[(channel[i1]^[dl[i1].nt].data) and $0f] or ((channel[i1]^[dl[i1].nt].data and $f0) shl 6);
           sl[i1].fr := fre;
           if channel[i1]^[dl[i1].nt].Data and $4000 = 0 then
             access($43+chnums[i1],((channel[i1]^[dl[i1].nt].data and $3f00)shr 8) or (Ins[CurIns[i1],3] and $c0),bport)
           else access($43+chnums[i1],Ins[CurIns[i1],3],bport);
           access($a0+i1,fre and $ff,bport);
           access($b0+i1,(fre shr 8) and 31+32,bport);
           sl[i1].on := false;
           dl[i1].on := false;
         end;
      end;
       if (Pl_count = 0) then
       begin
         for i1 := 0 to 8 do if snoff[i1] then soundoff(i1);
         for i1 := 0 to 8 do snoff[i1] := false;
         for i3 := maxoch downto 0 do
         if (Order[i3,Pl_Order[i3]].a1 <> 0) or
            (Order[i3,Pl_Order[i3]].a2 <> 0) then
         begin
           for i2 := 0 to maxch do
           begin
             if (Order[i3,Pl_Order[i3]].chs[i2]) then
             begin
               cnote := Pl_Note[i3] + Order[i3,Pl_Order[i3]].a1;
               cm := channel[i2]^[cNote].Cmd;
               i1 := channel[i2]^[cNote].data;
               TMEta := channel[i2]^[cNote].FMeta;
               while (TMeta <> nil) do
               begin
                 if TMeta <> nil then
                   case TMEta^.Cmd of
                     1  : begin
                            CurIns[i2] := TMEta^.Data and $ff;
                            setsound(i2);
                          end;
                     2  : UMF.tempo := TMEta^.Data and $ff;
                     3  : begin
                            bdval := bdval or  32;
                            access($bd,bdval,bport);
                          end;
                     4  : begin
                            bdval := bdval and $ef;
                            access($bd,bdval,bport);
                          end;
                     6  : access($40+chnums[i2],(TMEta^.data and $3f) or (Ins[CurIns[i2],2] and $c0),bport);
                     7  : access($43+chnums[i2],(TMEta^.data and $3f) or (Ins[CurIns[i2],3] and $c0),bport);
                     8  : begin
                            slide := tmeta^.data;
                            sl[i2].dir := 1;
                          end;
                     9  : begin
                            slide := tmeta^.data;
                            sl[i2].dir := 2;
                          end;
                     13 : begin
                            if tmeta^.data <= 16 then dela :=round( (tmeta^.data / 16) * umf.tempo)
                            else dela := 0;
                            dl[i2].on := true;
                            dl[i2].val:= dela;
                            dl[i2].nt := cnote;
                            cm := 0;
                          end;
                   end;
                   TMeta := TMEta^.next;
               end;
               case cm of
                 2  : begin
                        access($b0+i2,0,bport);
                        sl[i2].on := false;
                      end;
                 1  : begin
                        if channel[i2]^[cNote].Data and $80 = 0 then access($b0+i2,0,bport);
                        fre:= NotFreqs[(i1) and $0f] or ((i1 and $f0) shl 6);
                        sl[i2].fr := fre;
                        if channel[i2]^[cNote].Data and $4000 = 0 then
                          access($43+chnums[i2],((channel[i2]^[cNote].data and $3f00)shr 8),bport)
                        else access($43+chnums[i2],Ins[CurIns[i2],3],bport);
                        access($a0+i2,fre and $ff,bport);
                        access($b0+i2,(fre shr 8) and 31+32,bport);
                        sl[i2].on := false;
                      end;
               end;
               if slide <> 0 then begin
                      sl[i2].on := true;
                      sl[i2].val:= slide;
                      slide := 0;
                    end;

             end;
           end;
           if cNote < Order[i3,Pl_Order[i3]].a2 then inc(Pl_Note[i3])
           else
           begin
             Pl_Note[i3] := 0;
             if i3 = 0 then
             begin
               if (Order[0,Pl_Order[0]+1].a1 <> 0) or
                  (Order[0,Pl_Order[0]+1].a2 <> 0) then
                  for i4 := 0 to maxoch do
               begin
                 inc(Pl_Order[i4]);
                 Pl_Note[i4] := 0;
               end
               else for i4 := 0 to maxoch do
               begin
                 Pl_Order[i4] := 0;
                 Pl_Note[i4] := 0;
               end;
                 for i2 := 0 to 8 do if not order[0,pl_order[0]].chs[i2] then snoff[i2] := true;

             end
           end;
         end;
         Pl_Count := umf.tempo;       { huom! muutettavaa }
         if inson = 0 then CurNote := Pl_Note[0];
       end
       else dec(Pl_Count);
     end;
end;

procedure startPlay;
begin
  for in1 := 0 to maxoch do
  begin
    Pl_Note[in1]  := 0;
    Pl_Order[in1] := 0;
  end;
  Pl_Count:= 0;
  setintvec($1c,addr(playhandler));
  playon := not playon;
  for in1 := 0 to maxch do
  begin
    soundoff(in1);
    sl[in1].on := false;
  end;
end;

procedure PlayHandler2; Interrupt;
var fre,fre2,i1,i2,cm,cnote : word;
    slide :byte;
    delay :byte;
    TMEta :MetaPtr;
begin
     slide := 0;
     if (playon) then
     begin
      for i1 := 0to 8 do
      begin
       if sl[i1].on then
       begin
         if sl[i1].count = 0 then
         begin
           if sl[i1].dir = 1 then inc(sl[i1].fr,sl[i1].val and $f)
           else dec(sl[i1].fr,sl[i1].val and $f);
           access($a0+i1,sl[i1].fr and $ff,bport);
           access($b0+i1,(sl[i1].fr shr 8) and 31+32,bport);
           sl[i1].count := sl[i1].val shr 4;
         end else dec(sl[i1].count);
       end;
       if Dl[i1].on then
         if Dl[i1].val = umf.tempo - Pl2_Count then
         begin
           if channel[i1]^[Dl[i1].nt].Data and $80 = 0 then access($b0+i1,0,bport);
           fre:= NotFreqs[(channel[i1]^[dl[i1].nt].data) and $0f] or ((channel[i1]^[dl[i1].nt].data and $f0) shl 6);
           sl[i1].fr := fre;
           if channel[i1]^[dl[i1].nt].Data and $4000 = 0 then
             access($43+chnums[i1],((channel[i1]^[dl[i1].nt].data and $3f00)shr 8) or (Ins[CurIns[i1],3] and $c0),bport)
           else access($43+chnums[i1],Ins[CurIns[i1],3],bport);
           access($a0+i1,fre and $ff,bport);
           access($b0+i1,(fre shr 8) and 31+32,bport);
           sl[i1].on := false;
           dl[i1].on := false;
         end;
      end;
       if pl2_count = 0 then
       begin
         for i2 := 0 to maxch do
         begin
           cnote := Pl2_place + Pl2_note;
               cm := channel[i2]^[cNote].Cmd;
               i1 := channel[i2]^[cNote].data;
               TMEta := channel[i2]^[cNote].FMeta;
           while (TMeta <> nil) do
           begin
             if TMeta <> nil then
             case TMEta^.Cmd of
               1  : begin
                      CurIns[i2] := TMEta^.Data and $ff;
                      setsound(i2);
                    end;
               2  : UMF.Tempo := TMEta^.Data and $ff;
               3  : begin
                      bdval := bdval or  32;
                      access($bd,bdval,bport);
                    end;
               4  : begin
                      bdval := bdval and $ef;
                      access($bd,bdval,bport);
                    end;
               6  : access($40+chnums[i2],(TMEta^.data and $3f) or (Ins[CurIns[i2],2] and $c0),bport);
               7  : access($43+chnums[i2],(TMEta^.data and $3f) or (Ins[CurIns[i2],3] and $c0),bport);
               8  : begin
                      slide := tmeta^.data;
                      sl[i2].dir := 1;
                    end;
               9  : begin
                      slide := tmeta^.data;
                      sl[i2].dir := 2;
                    end;
               13 : begin
                      if tmeta^.data <= 16 then delay :=round( (tmeta^.data / 16) * umf.tempo)
                      else delay := 0;
                      dl[i2].on := true;
                      dl[i2].val:= delay;
                      dl[i2].nt := cnote;
                      cm := 0;
                    end;
             end;
             TMeta := TMEta^.next;
           end;
             case cm of
                 2  : begin
                        access($b0+i2,0,bport);
                        sl[i2].on := false;
                      end;
                 1  : begin
                        if channel[i2]^[cNote].Data and $80 = 0 then access($b0+i2,0,bport);
                        fre:= NotFreqs[(i1) and $0f] or ((i1 and $f0) shl 6);
                        sl[i2].fr := fre;
                        if channel[i2]^[cNote].Data and $4000 = 0 then
          access($43+chnums[i2],((channel[i2]^[cNote].data and $3f00)shr 8) or (Ins[CurIns[i2],3] and $c0),bport)
                        else access($43+chnums[i2],Ins[CurIns[i2],3],bport);
                        access($a0+i2,fre and $ff,bport);
                        access($b0+i2,(fre shr 8) and 31+32,bport);
                        sl[i2].on := false;
                      end;
             end;
           if slide <> 0 then begin
                      sl[i2].on := true;
                      sl[i2].val:= slide;
                      slide := 0;
                    end;
        end;
        if Pl2_note < segsize-1 then inc(Pl2_note)
        else Pl2_note := 0;
        pl2_count := umf.tempo;       { huom! muutettavaa }
        if inson = 0 then CurNote := cnote;
       end
       else dec(pl2_count);
     end;
end;

procedure startPlay2;
begin
  Pl2_Note  := 0;
  Pl2_Count := 0;
  if segsize = 0 then segsize := $10;
  Pl2_Place := segsize*(curnote div segsize);
  setintvec($1c,addr(playhandler2));
  playon := not playon;
  for in1 := 0 to maxch do
  begin
    soundoff(in1);
    sl[in1].on := false;
  end;
end;

procedure Init;
var i1 :word;
var s1 :string;
begin
     TextMode(Co80+Font8x8);
     Mark(HeapSt);
     SetVT;
     SetPIT($2000);
     soundinit;
     soundinit2;
     access(1,0,bport);
     access(8,0,bport);
     UMFName := 'UNTITLED.JZZ';
     CurOct  := 4;
     CurVol  := $40;
     CurSno  := 0;
     InsOn   := 2;
     SongChange := false;
     UMF.Title := 'No Name For This               ';
     UMF.tempo := $16;
     UMF.InsNum:= 0;
     UMF.Ver   := CurUMFVer;
     for i1 := 0 to 15 do GetPal(i1,OrgPal[i1].r,OrgPal[i1].g,OrgPal[i1].b);
     for i1 := 0 to 7 do Pal(i1,MyPal[i1].r,MyPal[i1].g,MyPal[i1].b);
     step := 1;
     for i1 := 0 to maxoch do
     begin
       PL_Order[i1] := 0;
       Pl_Note[i1] := 0;
     end;

     GetIntVec($1c,Int1cSave);

     segsize := 64;
     bdval :=0;

     bnkfile := 'SOUND.BNK   ';

     AreaOn2 := false;

     if initialized <> true then
     begin
      s1 := paramstr(1);
      if s1 <> '' then
      begin
        loadjzz(s1);
        if errcode = 0 then
        begin
          UMFName := s1;
          SongChange := false;
          startPlay;
        end;
      end;
    end;
    initialized := true;
end;

procedure StartScr;
var i1 : word;
begin
     TCol := $13;
     ClrVT;
     for i1 := 1 to winnum do
       PrWin(Win[i1].x1,Win[i1].y1,Win[i1].x2,
             Win[i1].y2,Win[i1].col,32);
     PrWin(AWin.x1,AWin.y1,AWin.x2,
           AWin.y2,AWin.col,32);
     for i1 := 0 to 8 do
       PrWin(MWin[i1].x1,mWin[i1].y1,mWin[i1].x2,
             MWin[i1].y2,mWin[i1].col,32);
     WrCol('                                PaRAlleL JAzZ v'+ver,0,0,$4e);
     WrXY('File:             Title:                                 Tempo:   Cur.Ins:',0,2);
     WrXY('  Addr    1       2       3       4       5       6       7       8       9    ',0,bplace);
     WrXY(':  :  :',70,49);
end;

procedure wrMeta(ch:byte;nt:word);
begin
     if Metapos < bplace -4 then
      begin
       if nt <= maxnote then
       begin
        tcol := $05;
        if (nt = curnote) and (ch = curch) then
        begin
          tcol := $30;
        end
        else
          case Channel[Ch]^[Nt].Cmd of
            1 : tcol := col_cmd;
            2 : tcol := col_cmd2;
          end;
        if Channel[Ch]^[Nt].Cmd <> 0 then
          wrcol(whex(Channel[ch]^[nt].Data),
               (ch - fMeta)*5+2,Metapos+4,tcol)
        else wrcol('ú úú',(ch - fMeta)*5+2,Metapos+4,tcol);

        CurMETa:= Channel[ch]^[nt].FMeta;
        inc(MetaPos);
        while (CurMETA <> nil) and (Metapos < bplace-4) do
        begin
             wrcol(Chr(96+CurMeta^.Cmd)+' '+
                     bhex(CurMeta^.Data),
                   (ch - fMeta)*5+2,Metapos+4,col_meta);
             inc(METApos);
             CurMeta := CurMeta^.next;
        end;
       end
       else inc(metapos);
      end;
end;

procedure WrCmd(x,y,ch:byte;nt:word);
var i1:byte;
begin
     case Channel[ch]^[nt].Cmd of
       1   : begin
               Wrcol(Freqs[Channel[ch]^[nt].Data and $0f],x,y,col_note);
               Wrcol(i2s(Channel[ch]^[nt].Data shr 4 and 7),x+2,y,col_note);
               if Channel[ch]^[nt].data and $4000 = 0 then
               begin
                 Wrcol(bhex((Channel[ch]^[nt].Data  and $3f00)shr 8),x+4,y,col_note);
               end
               else WrCol('úú',x+4,y,col_note);
               if Channel[ch]^[nt].data and $0080 = 0 then WrCol('o',x+6,y,col_note)
               else WrCol('þ',x+6,y,col_cmd);
             end;
       2   : begin
               Wrcol(' þþ þþ',x,y,col_note);
             end;
     end;
end;

procedure ScrVita;
var i1,i2 : word;
begin
     startscr;
     HndErr;
     for i1 := 2 to winnum do
       PrWin(Win[i1].x1,Win[i1].y1,Win[i1].x2,
             Win[i1].y2,Win[i1].col,32);
     for i1 := 0 to 8 do
       PrWin(NWin[i1].x1,NWin[i1].y1,NWin[i1].x2,
             NWin[i1].y2,NWin[i1].col,32);
     WrXY(UMFName,win[2].x1,win[2].y1);
     WrXY(UMF.Title,win[3].x1,win[3].y1);
     WrXY(bhex(UMF.Tempo),win[4].x1,win[4].y1);
     WrXY(i2s(CurIns[CurCh]),win[5].x1,win[5].y1);
     if PlayOn then wrXY('',79,49) else wrXY('þ',79,49);
     wrcol(bhex(step),77,49,col_umf or $10);
     wrcol(bhex(curoct),74,49,col_umf or $10);
     wrcol(bhex(segsize),71,49,col_umf or $10);
     wrcol(bhex(bdval),68,49,col_umf or $10);
     for i1 := 0 to 8 do
       PrWin(MWin[i1].x1,mWin[i1].y1,mWin[i1].x2,
             MWin[i1].y2,mWin[i1].col,32);

     for i1 := 0 to maxch do
     begin
       for i2 := 0 to 47-bplace do
       begin
         if Channel[i1]^[i2+faddr].Cmd <> 0 then
         begin
           WrCmd(NWin[i1].x1,bplace+1+i2,i1,i2+faddr);
         end
         else Wrcol(Wait_norm,NWin[i1].x1,bplace+1+i2,col_note);
       end;
     end;

     for i1 := 0 to maxch do
     begin
       for i2 := 0 to bplace-5 do
       begin
           WrMEta(i1,i2+curnote-((bplace -5)div 2));
       end;
       MetaPos := 0;
     end;


     for i1 := 0 to 47-bplace do                 { write the Addr numbers }
     begin
       WrXY(whex(FAddr+i1),2,bplace+1+i1);
       if (faddr+i1) and $0f = 8 then PrFColWin(6,bplace+1+i1,78,bplace+1+i1,$07)
       else if (faddr+i1) and $0f = 0 then PrFColWin(6,bplace+1+i1,78,bplace+1+i1,$0e);
     end;

     if AreaOn2 then
     begin
     if Area.x2 < Area.x1 then
       begin i1 := Area.x1; Area.x1 := Area.x2; Area.x2 := i1; end;
     if Area.y2 < Area.y1 then
       begin i1 := Area.y1; Area.y1 := Area.y2; Area.y2 := i1; end;

     if (Area.y1 >= faddr) and (Area.y1 <= faddr+47-bplace) then
       begin
         if (Area.y2 <= faddr+47-bplace) then
         begin
           for i1 := Area.x1 to Area.x2 do
             prColWin(NWin[i1].x1,bplace+1+Area.y1 - faddr,
                      NWin[i1].x2,bplace+1+Area.y2 - faddr,col_area);
         end
         else
           for i1 := Area.x1 to Area.x2 do
               PrColWin(NWin[i1].x1,bplace+1+Area.y1 - faddr,
                      NWin[i1].x2,48,col_area);
       end
       else
         if (Area.y2 >= faddr) and (Area.y2 <=faddr+47-bplace) then
         begin
             for i1 := Area.x1 to Area.x2 do
               prColWin(NWin[i1].x1,bplace+1,
                    NWin[i1].x2,bplace+1+Area.y2 - faddr,col_area);
         end
         else
           if (Area.y1 < faddr) and (Area.y2 > faddr+47-bplace) then
             for i1 := Area.x1 to Area.x2 do
               prColWin(NWin[i1].x1,bplace+1,
                        NWin[i1].x2,48,col_area);
   end;
end;

procedure PrCur;
var i:byte;
begin
     case inson of
       0  :i := col_cur;
       1  :i := col_ins;
       2  :i := col_ent;
     end;
     mem[tseg:(TPos.y*80+TPos.x)shl 1 +1] := i;
end;

procedure check(n:byte);
begin
     if CurPos = n then TCol := $5f
     else TCol := $05;
end;
procedure soundon(ch:Byte;fr:word);
          var prt:word;
          begin
               if ch > 8 then ch := ch-9;
               prt := bport;
               access($20+chnums[ch],ins[curins[curch],0],bport);
               access($23+chnums[ch],ins[CurIns[CurCh],1],bport);
               access($40+chnums[ch],ins[CurIns[CurCh],2],bport);
               access($43+chnums[ch],ins[CurIns[CurCh],3],bport);
               access($60+chnums[ch],ins[CurIns[CurCh],4],bport);
               access($63+chnums[ch],ins[CurIns[CurCh],5],bport);
               access($80+chnums[ch],ins[CurIns[CurCh],6],bport);
               access($83+chnums[ch],ins[CurIns[CurCh],7],bport);
               access($e0+chnums[ch],ins[CurIns[CurCh],8],bport);
               access($e3+chnums[ch],ins[CurIns[CurCh],9],bport);
               access($c0+ch,ins[CurIns[CurCh],10],bport);
               access($a0+ch,fr and $ff,prt);
               access($b0+ch,fr shr 8 and 31+32,prt);

          end;{testinson}

procedure Inston(ch,cins:Byte;fr:word);
          var prt:word;
          begin
               if ch > 8 then ch := ch-9;
               prt := bport;
               access($20+chnums[ch],ins[CIns,0],bport);
               access($23+chnums[ch],ins[CIns,1],bport);
               access($40+chnums[ch],ins[CIns,2],bport);
               access($43+chnums[ch],ins[CIns,3],bport);
               access($60+chnums[ch],ins[CIns,4],bport);
               access($63+chnums[ch],ins[CIns,5],bport);
               access($80+chnums[ch],ins[CIns,6],bport);
               access($83+chnums[ch],ins[CIns,7],bport);
               access($e0+chnums[ch],ins[CIns,8],bport);
               access($e3+chnums[ch],ins[CIns,9],bport);
               access($c0+ch,ins[CIns,10],bport);
               access($a0+ch,fr and $ff,prt);
               access($b0+ch,fr shr 8 and 31+32,prt);

          end;{testinson}

procedure loadsound(n,nto:integer);
          var a:integer;

              f:text;
              c:char;
          begin
               n := n*16;
               Assign(f,bnkfile);
               Reset(f);
               for a:=1 to n do read(f,c);

               for a:=0 to 15 do
               begin
                    read(f,c);
                    ins[nto,a]:=ord(c);
               end;
               close(f);
          end;{loadsound}

procedure savesound(nto,n:integer);
          var i1,i2:integer;
              arr:array[0..255,0..15] of byte;
              f:text;
              c:char;
          begin
               Assign(f,bnkfile);
               Reset(f);
               i1:= 0;
               i2 := 0;
               while (not eof(f)) and (i1 < 256) do
               begin
                 for i2 := 0 to 15 do
                 begin
                   read(f,c);
                   arr[i1,i2] := ord(c);
                 end;
                 inc(i1);
               end;
               close(f);
               for i2 := 0 to 15 do
                 arr[nto,i2] := Ins[n,i2];
               rewrite(f);
               for i1 := 0 to 255 do
                 for i2 := 0 to 15 do
                   write(f,chr(arr[i1,i2]));
               close(f);
          end;{savesound}

procedure sounds;
var
  i1,cins:byte;
  valinc :shortint;
  lins,sins  :byte;
  TempPos     :POSRec;
const
  IReg:array[4..29] of byte = (8,9,4,5,4,5,6,7,6,7,2,3,2,3,0,1,0,1,0,1,0,1,0,1,10,10);
  MaxVal:array[4..29]of byte= (1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,0,0,0,0,0,0,0,2,0);

begin
  TempPos := TPos;
  cins := curins[curch];
  CurPos := 0;
  repeat
  bordwin(owin[2].x1,owin[2].y1,owin[2].x2,owin[2].y2,owin[2].col,owin[2].col);
  WrCol('Sound Generator',owin[2].x1+5,owin[2].y1-1,$16);
  WrXY('Bank File',owin[2].x1,owin[2].y1);
  WrXY('Instrument #',owin[2].x1,owin[2].y1+3);
  WrCol('Values           Mod  Car',owin[2].x1,owin[2].y1+5,$16);
  WrXY('Waveform',owin[2].x1,owin[2].y1+6);
  WrXY('Attack',owin[2].x1,owin[2].y1+7);
  WrXY('Decay',owin[2].x1,owin[2].y1+8);
  WrXY('Sustain',owin[2].x1,owin[2].y1+9);
  WrXY('Release',owin[2].x1,owin[2].y1+10);
  WrXY('Scaling',owin[2].x1,owin[2].y1+12);
  WrXY('Output',owin[2].x1,owin[2].y1+13);
  WrXY('Fr. Multiple',owin[2].x1,owin[2].y1+15);
  WrXY('Amp. Modulation',owin[2].x1,owin[2].y1+16);
  WrXY('Vibrato',owin[2].x1,owin[2].y1+17);
  WrXY('EG type',owin[2].x1,owin[2].y1+18);
  WrXY('Key Scaling',owin[2].x1,owin[2].y1+19);
  WrXY('Feedback',owin[2].x1,owin[2].y1+21);
  WrXY('Algorithm',owin[2].x1,owin[2].y1+22);
    check(0);
    WrCol(bnkfile,owin[2].x1+11,owin[2].y1,tcol);
    check(1);
    WrCol('Load Sound',owin[2].x1,owin[2].y1+1,tcol);
    check(2);
    WrCol('Save Sound',owin[2].x1,owin[2].y1+2,tcol);
    check(3);
    WrCol(bhex(cins),owin[2].x1+13,owin[2].y1+3,TCol);
    check(4);
    WrCol(i2s(Ins[cins,8]),owin[2].x1+17,owin[2].y1+6,TCol);
    check(5);
    WrCol(i2s(Ins[cins,9]),owin[2].x1+22,owin[2].y1+6,TCol);
    check(6);
    WrCol(i2s((Ins[cins,4]and $f0) shr 4),owin[2].x1+17,owin[2].y1+7,TCol);
    check(7);
    WrCol(i2s((Ins[cins,5]and $f0) shr 4),owin[2].x1+22,owin[2].y1+7,TCol);
    check(8);
    WrCol(i2s((Ins[cins,4]and $0f)),owin[2].x1+17,owin[2].y1+8,TCol);
    check(9);
    WrCol(i2s((Ins[cins,5]and $0f)),owin[2].x1+22,owin[2].y1+8,TCol);
    check(10);
    WrCol(i2s((Ins[cins,6]and $f0) shr 4),owin[2].x1+17,owin[2].y1+9,TCol);
    check(11);
    WrCol(i2s((Ins[cins,7]and $f0) shr 4),owin[2].x1+22,owin[2].y1+9,TCol);
    check(12);
    WrCol(i2s((Ins[cins,6]and $0f)),owin[2].x1+17,owin[2].y1+10,TCol);
    check(13);
    WrCol(i2s((Ins[cins,7]and $0f)),owin[2].x1+22,owin[2].y1+10,TCol);
    check(14);
    WrCol(i2s((Ins[cins,2]and $c0) shr 6),owin[2].x1+17,owin[2].y1+12,TCol);
    check(15);
    WrCol(i2s((Ins[cins,3]and $c0) shr 6),owin[2].x1+22,owin[2].y1+12,TCol);
    check(16);
    WrCol(i2s((Ins[cins,2]and $3f)),owin[2].x1+17,owin[2].y1+13,TCol);
    check(17);
    WrCol(i2s((Ins[cins,3]and $3f)),owin[2].x1+22,owin[2].y1+13,TCol);
    check(18);
    WrCol(i2s((Ins[cins,0]and $0f)),owin[2].x1+17,owin[2].y1+15,TCol);
    check(19);
    WrCol(i2s((Ins[cins,1]and $0f)),owin[2].x1+22,owin[2].y1+15,TCol);
    check(20);
    WrCol(i2s((Ins[cins,0]and $80) shr 7),owin[2].x1+17,owin[2].y1+16,TCol);
    check(21);
    WrCol(i2s((Ins[cins,1]and $80) shr 7),owin[2].x1+22,owin[2].y1+16,TCol);
    check(22);
    WrCol(i2s((Ins[cins,0]and $40) shr 6),owin[2].x1+17,owin[2].y1+17,TCol);
    check(23);
    WrCol(i2s((Ins[cins,1]and $40) shr 6),owin[2].x1+22,owin[2].y1+17,TCol);
    check(24);
    WrCol(i2s((Ins[cins,0]and $20) shr 5),owin[2].x1+17,owin[2].y1+18,TCol);
    check(25);
    WrCol(i2s((Ins[cins,1]and $20) shr 5),owin[2].x1+22,owin[2].y1+18,TCol);
    check(26);
    WrCol(i2s((Ins[cins,0]and $10) shr 4),owin[2].x1+17,owin[2].y1+19,TCol);
    check(27);
    WrCol(i2s((Ins[cins,1]and $10) shr 4),owin[2].x1+22,owin[2].y1+19,TCol);
    check(28);
    WrCol(i2s((Ins[cins,10]and $0e) shr 1),owin[2].x1+19,owin[2].y1+21,TCol);
    check(29);
    WrCol(i2s((Ins[cins,10]and 1)),owin[2].x1+19,owin[2].y1+22,TCol);
    PrVT;
    key := getkey;
    i1 := CheckKeys(Key);
    if i1 <> 0 then
    begin
      soundoff(curch);
      Inston(curch,cins,NotFreqs[i1 and $0f] or ((i1 and $70) shl 6));
    end;
    valinc := 0;
    case key of
      $4800  : if curpos in [0..4,29] then dec(curpos) else dec(CurPos,2);
      $5000  : if curpos in [27..29,0..3] then inc(curpos) else inc(curpos,2);
      $4b00  : dec(curpos);
      $4d00  : inc(curpos);
      $4e2b  : valinc := 1;
      $4a2d  : valinc := -1;
{/}    $352f   : if curoct > 0 then dec(curoct);
{*}    $372a   : if curoct < 7 then inc(curoct);
      $1c0d  : case curpos of
                 2  : begin
                        Prwin(Owin[2].x1+11,OWin[2].y1+2,Owin[2].x2,
                              OWin[2].y1+2,OWin[2].col,32);
                        WrXY('#',OWin[2].x1+11,OWin[2].y1+2);
                        RdInt(sIns,OWin[2].x1+12,OWin[2].y1+2,3,col_note);
                        SaveSound(sins,cins);
                      end;
                 1  : begin
                        Prwin(Owin[2].x1+11,OWin[2].y1+1,Owin[2].x2,
                              OWin[2].y1+1,OWin[2].col,32);
                        WrXY('#',OWin[2].x1+11,OWin[2].y1+1);
                        RdInt(LIns,OWin[2].x1+12,OWin[2].y1+1,3,col_note);
                        LoadSound(lins,cins);
                      end;
                 0  : RdXY(bnkfile,OWin[2].x1+11,OWin[2].y1,12,col_note);
               end;

   {   $1c0d  : begin
                 case curpos of
                  1   : GoXY(Owin[2].x1+13,OWin[2].y1+1);
                  2   : GoXY(Owin[2].x1+17,OWin[2].y1+4);
                  3   : GoXY(Owin[2].x1+22,OWin[2].y1+4);
                  4   : GoXY(Owin[2].x1+17,OWin[2].y1+5);
                  5   : GoXY(Owin[2].x1+22,OWin[2].y1+5);
                  6   : GoXY(Owin[2].x1+17,OWin[2].y1+6);
                  7   : GoXY(Owin[2].x1+22,OWin[2].y1+6);
                  8   : GoXY(Owin[2].x1+17,OWin[2].y1+7);
                  9   : GoXY(Owin[2].x1+22,OWin[2].y1+7);
                  10  : GoXY(Owin[2].x1+17,OWin[2].y1+8);
                  11  : GoXY(Owin[2].x1+22,OWin[2].y1+8);
                  12  : GoXY(Owin[2].x1+17,OWin[2].y1+10);
                  13  : GoXY(Owin[2].x1+22,OWin[2].y1+10);
                  14  : GoXY(Owin[2].x1+17,OWin[2].y1+11);
                  15  : GoXY(Owin[2].x1+22,OWin[2].y1+11);
                  16  : GoXY(Owin[2].x1+17,OWin[2].y1+13);
                  17  : GoXY(Owin[2].x1+22,OWin[2].y1+13);
                  18  : GoXY(Owin[2].x1+17,OWin[2].y1+14);
                  19  : GoXY(Owin[2].x1+22,OWin[2].y1+14);
                  20  : GoXY(Owin[2].x1+17,OWin[2].y1+15);
                  21  : GoXY(Owin[2].x1+22,OWin[2].y1+15);
                  22  : GoXY(Owin[2].x1+17,OWin[2].y1+16);
                  23  : GoXY(Owin[2].x1+22,OWin[2].y1+16);
                  24  : GoXY(Owin[2].x1+17,OWin[2].y1+17);
                  25  : GoXY(Owin[2].x1+22,OWin[2].y1+17);
                  26  : GoXY(Owin[2].x1+19,OWin[2].y1+19);
                  27  : GoXY(Owin[2].x1+19,OWin[2].y1+20);
                 end;
                 if (curpos >= 2) and (curpos <= 27) then
                   Ins[CIns,IReg[Curpos]] := ReadI(MaxVal[CurPos])
                 else if curpos = 1 then cins := ReadI(2);
               end;}
    end;
    if valinc <> 0 then
        case curpos of
          3  : inc(cins,valinc);
          4  : inc(Ins[Cins,IReg[CurPos]],valinc);
          5  : inc(Ins[Cins,IReg[CurPos]],valinc);
          6  : inc(Ins[Cins,IReg[CurPos]],valinc*16);
          7  : inc(Ins[Cins,IReg[CurPos]],valinc*16);
          8  : inc(Ins[Cins,IReg[CurPos]],valinc);
          9  : inc(Ins[Cins,IReg[CurPos]],valinc);
          10 : inc(Ins[Cins,IReg[CurPos]],valinc*16);
          11 : inc(Ins[Cins,IReg[CurPos]],valinc*16);
          12 : inc(Ins[Cins,IReg[CurPos]],valinc);
          13 : inc(Ins[Cins,IReg[CurPos]],valinc);
          14 : inc(Ins[Cins,IReg[CurPos]],valinc shl 6);
          15 : inc(Ins[Cins,IReg[CurPos]],valinc shl 6);
          16 : inc(Ins[Cins,IReg[CurPos]],valinc);
          17 : inc(Ins[Cins,IReg[CurPos]],valinc);
          18 : inc(Ins[Cins,IReg[CurPos]],valinc);
          19 : inc(Ins[Cins,IReg[CurPos]],valinc);
          20 : Ins[Cins,IReg[CurPos]] := Ins[Cins,IReg[CurPos]] xor $80;
          21 : Ins[Cins,IReg[CurPos]] := Ins[Cins,IReg[CurPos]] xor $80;
          22 : Ins[Cins,IReg[CurPos]] := Ins[Cins,IReg[CurPos]] xor $40;
          23 : Ins[Cins,IReg[CurPos]] := Ins[Cins,IReg[CurPos]] xor $40;
          24 : Ins[Cins,IReg[CurPos]] := Ins[Cins,IReg[CurPos]] xor $20;
          25 : Ins[Cins,IReg[CurPos]] := Ins[Cins,IReg[CurPos]] xor $20;
          26 : Ins[Cins,IReg[CurPos]] := Ins[Cins,IReg[CurPos]] xor $10;
          27 : Ins[Cins,IReg[CurPos]] := Ins[Cins,IReg[CurPos]] xor $10;
          28 : inc(Ins[Cins,IReg[CurPos]],valinc shl 1);
          29 : Ins[Cins,IReg[CurPos]] := Ins[Cins,IReg[CurPos]] xor 1;
        end;
    if curpos > 29 then if curpos < 40 then curpos := 0 else curpos := 29;
   { for i1 := 0 to maxch do setsound(i1);}
  until (key = $011b) or (key = $3b00);
  Tpos := TempPos;
end;
function PrQuestion(str1:string;col:byte):byte;
var i1,i2:byte;
begin
  i1 := 40-(length(str1) div 2);
  i2 := i1 + length(str1) ;
  BordWin(i1,24,i2,24,$03,col);
  wrxy(str1,i1,24);
  PrVT;
  gotoxy(i2+1,25);
  cursoron;
  key := getkey;
  if key and $ff in [ord('y'),ord('n')] then WrXY(chr(key and$ff),i2,24);
  PrVT;
  if key = $1579 then PrQuestion := 1
    else if key = $316e then PrQuestion := 2
      else PrQuestion := 0;
  cursoroff;
end;

procedure NewSong;
begin
  Release(HeapSt);
  SetIntVec($1c,Int1csave);
  endo := true;
end;

procedure SaveCurSong;
begin
  savejzz(UmfName);
  if errcode = 0 then songchange := false;
end;

procedure LoadSong;
var s1:strinG;
begin
  if songchange then
  begin
   case PrQuestion('Save Changes to '+UMFName+'?',$03) of
    1  : begin
           SaveCurSong;
         end;
    0  : exit;
   end;
  end;
  BordWin(OWin[3].x1,OWin[3].y1,OWin[3].x2,OWin[3].y2,OWin[3].col,OWin[3].col);
  WrXY('FileName',OWin[3].x1,OWin[3].y1);
  RdXY(s1,OWIn[3].x1+9,owin[3].y1,12,$05);
  ErrCode := 0;
  if s1 <> '' then
  begin
    if copy(s1,length(s1)-3,1) <> '.' then s1 := s1+'.jzz';
    loadjzz(s1);
    if errcode = 0 then
    begin
      UMFName := s1;
      SongChange := false;
    end;
    endo := true;

  end;
  HndErr;
  faddr := 0;
  fmeta := 0;
  CurHome;
end;

procedure SaveSong;
var s1:strinG;
begin
  BordWin(OWin[3].x1,OWin[3].y1,OWin[3].x2,OWin[3].y2,OWin[3].col,OWin[3].col);
  WrXY('FileName',OWin[3].x1,OWin[3].y1);
  RdXY(s1,OWIn[3].x1+9,owin[3].y1,12,$05);
  if s1 <> '' then
  begin
    if copy(s1,length(s1)-3,1) <> '.' then s1 := s1+'.jzz';
    savejzz(s1);
    if errcode = 0 then
    begin
      UmfName := s1;
      songchange := false;
    end;
    endo := true;
  end;
  ErrCode := 0;
  CurHome;
end;

procedure SetupSong;
begin
  curpos := 0;
  bordWin(OWin[4].x1,OWin[4].y1,OWin[4].x2,OWin[4].y2,
          OWin[4].col,OWin[4].col);
  WrCol('Song Setup',OWin[4].x1 +((OWin[4].x2-OWIn[4].x1)div 2)-5,OWin[4].y1-1,$16);
  WrXY('Title',OWin[4].x1,OWin[4].y1);
  WrXY('Segment size',OWin[4].x1,OWin[4].y1+1);
  WrXY('Tempo',OWin[4].x1,OWin[4].y1+2);
  repeat
  check(0);
  WrCol(UMF.Title,OWin[4].x1+12,OWin[4].y1,tcol);
  check(1);
  WrCol(i2s(SegSize),OWin[4].x1+12,OWin[4].y1+1,tcol);
  check(2);
  WrCol(i2s(UMF.Tempo),OWin[4].x1+12,OWin[4].y1+2,tcol);
  PrVT;
  key := getkey;
  case key of
    $4800 : dec(curpos);
    $5000 : inc(CurPos);
    $1c0d : case curpos of
              0 : rdStr(UMF.Title,OWin[4].x1+12,OWin[4].y1,32,$05);
              1 : RdInt(SegSize,OWin[4].x1+12,OWin[4].y1+1,3,$05);
              2 : RdInt(UMF.tempo,OWin[4].x1+12,OWin[4].y1+2,1,$05);
            end;

  end;
  if curpos = 255 then curpos := 2
  else if curpos = 3 then curpos := 0;
  until key = $011b;
end;

procedure MetaEdit;
var k,i2,i3:word;
    i1,Curm:byte;
    TMeta:MetaPtr;
begin
   i2 := 0;
   i1 := 0;
   curm := 0;
   TMeta := Channel[CurCh]^[CurNote].FMeta;
   bordwin(NWin[curch].x1,Tpos.y,NWin[curch].x1+3,TPos.y,$03,$03);
   TPos.x := NWin[CurCh].x1;
   repeat
     if i1 <> 0 then
       WrXY(chr($40 + i1)+' '+bhex(i2),NWin[curch].x1,Tpos.y)
     else WrXY('ú 00',NWin[curch].x1,Tpos.y);

     PrVT;
     PrCur;
     k := getkey;
     if (Tpos.x = NWin[curch].x1) then
     begin
       if (k and $ff in [$61..$61+mcnum]) then
       begin
         i1 := (k and $ff)-$60;
         inc(TPos.x,2);
       end;
     end
     else
       if k and $ff in [$30..$39,$61..$66] then
       begin
         i2 := i2 and not($0f shl (4*(1-(Tpos.x-NWin[CurCh].x1-2))));
         if k and $ff in [$30..$39] then i3 := (k and $ff)-$30
         else i3 := (k and $ff)-$57;
         i2 := i2 or (i3 shl (4*(1-(TPos.x-NWin[CurCh].x1-2))));
         if Tpos.x = NWin[Curch].x1+2 then inc(Tpos.x);
       end;
     case k of
       $4b00 : if Tpos.x = NWin[curch].x1+2 then dec(Tpos.x,2)
               else
                 if Tpos.x = NWin[curch].x1+3 then dec(TPos.x);

       $4d00 : if Tpos.x = NWin[curch].x1 then inc(Tpos.x,2)
               else
                 if Tpos.x = NWin[curch].x1+2 then inc(TPos.x);
       $5300 : delmeta(CurCh,CurNote,1);
     end;
   until (k = $011b) or (k = $1c0d) or (k = $2915) or (k = $5300);
   if k = $1c0d then Changemeta(CurCh,CurNote,i1,i2);
   TPos.x := NWin[CurCh].x1;
end;

procedure OrderEdit;
var i1,i2,i3,k:word;
    hpos :posrec;
    haddr:byte;
    hord :byte;
    hch  :byte;
begin
     hpos.x := owin[5].x1;
     hpos.y := owin[5].y1;
     haddr  := 0;
     hch    := 0;
     hord   := 0;
     bordwin(owin[5].x1,owin[5].y1,owin[5].x2,owin[5].y2,
             owin[5].col,owin[5].col);

     WrCol('Order Generator',OWin[5].x1 +((OWin[5].x2-OWIn[5].x1)div 2)-7,OWin[5].y1-1,$16);
   repeat
     for i1 := 0 to maxoch do
      prwin(2+(i1*19),owin[5].y1,((i1+1)*19),owin[5].y2,5,32);
     for i1 := 0 to maxoch do
       for i2 := 0 to owin[5].y2-owin[5].y1 do
         begin
           WrXY(whex(Order[i1,i2+haddr].a1)+'-'+whex(order[i1,i2+haddr].a2),
                2+(i1*19),owin[5].y1+i2);
           for i3 := 0to 8 do
             if order[i1,i2+haddr].chs[i3] then wrcol('þ',2+(i1*19)+9+i3,owin[5].y1+i2,$07)
             else wrcol('ú',2+(i1*19)+9+i3,owin[5].y1+i2,$07);

         end;
     PrVT;
     mem[tseg:(hPos.y*80+hPos.x)shl 1 +1] := col_ent;

     k := getkey;
     case k of
 {Up}  $4800   : begin
                   if hPos.y > owin[5].y1 then dec(hpos.y)
                   else if haddr > 0 then dec(haddr);
                 end;

 {Dn}  $5000   : begin
                   if hPos.y < owin[5].y2 then inc(hPos.y)
                   else if haddr+owin[5].y2-owin[5].y1-1 < maxord then inc(haddr);
                 end;

 {Lt}  $4b00   : begin
                   if hPos.x in [2+(hch*19)+1..2+(hch*19)+3,
                                 2+(hch*19)+6..2+(hch*19)+17]
                     then dec(hPos.x)
                   else
                   begin
                     if (hch > 0) and (hpos.x = 2+(hch*19)) then
                     begin
                       dec(hch);
                       hPos.x := ((hch+1)*19) ;
                     end
                     else if hPos.x = 2+(hch*19)+5 then dec(hpos.x,2);
                   end;
                 end;

 {Rt}  $4d00   : begin
                   if hPos.x in [2+(hch*19)..2+(hch*19)+2,
                                 2+(hch*19)+5..2+(hch*19)+16]
                     then inc(hPos.x)
                   else
                   begin
                     if (hch < maxoch) and (hpos.x = 2+(hch*19)+17) then
                     begin
                       inc(hch);
                       hPos.x := 2+(hch*19);
                     end
                     else if hpos.x = 2+(hch*19)+3 then inc(hpos.x,2);
                   end;
                 end;
 {tab} $0f09  : if hPos.x+19 < OWin[5].x2 then
                                          begin
                                           inc(hPos.x,19);
                                           inc(hch);
                                          end
                else begin
                          hPos.x := 2+(maxoch*19);
                          hch := maxoch;
                     end;

 {TAB} $0f00   : if hpos.x -19 > 2 then
                   begin
                     dec(hPos.x,19);
                     dec(hch);
                   end
                   else begin
                     hPos.x := 2;
                     hch := 0;
                   end;

{PgDn} $5100   : if hpos.y = owin[5].y2 then
                            begin
                              if haddr < maxord-((Owin[5].y2-owin[5].y1) * 2) then
                              begin
                                inc(haddr,Owin[5].y2-owin[5].y1);
                              end
                              else begin
                                haddr := maxord - (Owin[5].y2-owin[5].y1);
                              end;
                            end
                            else begin
                              hPos.y := owin[5].y2;
                            end;
{PgUp} $4900   : if hPos.y > owin[5].y1 then
                            begin
                              hPos.y := owin[5].y1;
                            end
                            else begin
                              if haddr > Owin[5].y2-owin[5].y1 then
                              begin
                                dec(haddr,Owin[5].y2-owin[5].y1);
                              end
                              else begin
                                     hpos.y := owin[5].y1;
                                     haddr := 0;
                                   end;
                            end;
{entr} $1c0d   : begin
                   for i1 := maxord downto hord +1 do
                     Order[hch,i1] := Order[hch,i1-1];
                   order[hch,hord] := emptyorder;
                 end;
{del}  $5300   : begin
                   for i1 := hord to maxord-1 do
                      Order[hch,i1] := Order[hch,i1+1];
                   Order[hch,maxord] := emptyorder;
                 end;
    end;


    case hpos.x of
      2..5,
      21..24,
      40..43,
      59..62 : begin
                 if k and $ff in [$30..$39,$61..$66] then
                 begin
                   order[hch,hord].a1 := order[hch,hord].a1 and not($0f shl (4*(3-(hpos.x-(2+(hch*19))))));
                   if k and $ff in [$30..$39] then i3 := (k and $ff)-$30
                   else i3 := (k and $ff)-$57;
                   order[hch,hord].a1 := order[hch,hord].a1 or (i3 shl (4*(3-(hPos.x-(2+(hch*19))))));
                   if hpos.x < 2+(hch*19)+3 then inc(hpos.x)
                   else inc(hpos.x,2);
                 end;
               end;

      7..10,
      26..29,
      45..48,
      64..67 : begin
                 if k and $ff in [$30..$39,$61..$66] then
                 begin
                   order[hch,hord].a2 := order[hch,hord].a2 and not($0f shl (4*(3-(hpos.x-(2+(hch*19)+5)))));
                   if k and $ff in [$30..$39] then i3 := (k and $ff)-$30
                   else i3 := (k and $ff)-$57;
                   order[hch,hord].a2 := order[hch,hord].a2 or (i3 shl (4*(3-(hPos.x-(2+(hch*19)+5)))));
                   if hpos.x < 2+(hch*19)+9 then inc(hpos.x)
                 end;
               end;

      11..19,
      30..38,
      49..57,
      68..76 : begin
               if k and $ff in [32,13] then
               begin
                 order[hch,hord].chs[hpos.x-(2+(hch*19)+9)] :=
                 not order[hch,hord].chs[hpos.x-(2+(hch*19)+9)];
                 if hpos.x < 2+(hch*19)+17 then inc(hpos.x)
               end
               else if k and $ff in [$31..$39] then
               begin
                 order[hch,hord].chs[(k and $ff)-$31] :=
                 not order[hch,hord].chs[(k and $ff)-$31];
               end;
               case k of
                 $2915 : for i1 := 0 to 8 do
                           Order[hch,hord].chs[i1] := not Order[hch,hord].chs[i1];
                 $1e61 : for i1 := 0 to 8 do
                           Order[hch,hord].chs[i1] := true;
               end;
               end;
    end;
    hord := haddr + hpos.y - owin[5].y1;
    until (k = $011b) or (k = $3e00);
end;

begin
2:
     Init;
     cursoroff;
     access($bd,192,bport);
     StartScr;
     CurHome;
     repeat
     ScrVita;
     PrVT;
     PrCur;
       key := getkey;
       in3 := 1;
       in4 := 0;
       if key = $5200 then if inson = 2 then inson := 0 else inc(InsOn);
     { edit place differences }
       case TPos.x of
        7..8,
        15..16,
        23..24,
        31..32,
        39..40,
        47..48,
        55..56,
        63..64,
        71..72  : begin
                    in1 := CheckKeys(key);
                    in4 := 1;
                    case key of

                      $3920   : if Channel[curch]^[CurNote].Cmd <> 0
                                  then in3 := 0
                                  else in3 := 2;

                    end;
                    if (in1 <> 0) or (in3 <> 1) then
                    begin
                      if inson = 1 then InsSpace(curch,curnote,1);
                      Channel[curch]^[CurNote].Cmd := in3;
                      Channel[curch]^[CurNote].Data:= Channel[curch]^[CurNote].Data and $8000;
                      Channel[curch]^[CurNote].Data:= Channel[curch]^[CurNote].Data or (in1 and $7f);
                      Channel[curch]^[CurNote].Data:= Channel[curch]^[CurNote].Data or (CurVol shl 8);
                      Channel[curch]^[CurNote].Data:= Channel[curch]^[CurNote].Data or (Cursno);
                      if inson = 2 then if TPos.y < 49-step then inc(TPos.y,step)
                      else if faddr+48-bplace+step < maxnote then inc(Faddr,step);
                      if inson <> 0 then
                      begin
                        soundoff(curch);
                        soundon(curch,NotFreqs[in1 and $0f] or ((in1 and $70) shl 6));
                      end;
                      SongChange := true;
                    end
                  end;

      end;
    if inson <> 0 then
    begin
      case TPos.x of
        9,
        17,
        25,
        33,
        41,
        49,
        57,
        65,
        73  : begin
                if key and $ff in [$30..$39] then
                begin
                  in1 := (key and $ff)-$30;
                  in4 := 2;
                  if Channel[curch]^[CurNote].Cmd = 1 then
                  begin
                    Channel[CurCh]^[CurNote].Data := Channel[CurCh]^[CurNote].Data and $ff8f;
                    Channel[CurCh]^[CurNote].Data := Channel[CurCh]^[CurNote].Data or (in1 shl 4);
                    CurOct := in1;
                    if inson = 2 then if TPos.y < 49-step then inc(TPos.y,step)
                    else if faddr+48-bplace+step < maxnote then inc(Faddr,step);
                  end;
                  SongChange := true;
                end;
              end;

        11,
        19,
        27,
        35,
        43,
        51,
        59,
        67,
        75  : begin
                if key and $ff in [$30..$39,$61..$66] then
                begin
                  if key and $ff in [$30..$39] then in1 := (key and $ff)-$30
                  else in1 := (key and $ff)-$57;
                  in4 := 3;
                  if Channel[curch]^[CurNote].Cmd = 1 then
                  begin
                    if Channel[curch]^[CurNote].Data and $4000 <> 0 then
                       Channel[curch]^[CurNote].Data := Channel[curch]^[CurNote].Data and $c0ff;
                    Channel[curch]^[CurNote].Data := Channel[curch]^[CurNote].Data and $0fff;
                    Channel[curch]^[CurNote].Data := Channel[curch]^[CurNote].Data + (in1 shl 12);
                    CurVol := (Channel[curch]^[CurNote].Data and $ff00) shr 8;
                    inc(TPos.x);
                  end;
                  SongChange := true;
                end
                else if (key = $3920) or (key = $342e) then
                begin
                  Channel[curch]^[CurNote].Data := Channel[curch]^[CurNote].Data or $4000;
                  curvol := $40;
                end;
              end;

        12,
        20,
        28,
        36,
        44,
        52,
        60,
        68,
        76  : begin
                if key and $ff in [$30..$39,$61..$66] then
                begin
                  if key and $ff in [$30..$39] then in1 := (key and $ff)-$30
                  else in1 := (key and $ff)-$57;
                  in4 := 3;
                  if Channel[curch]^[CurNote].Cmd = 1 then
                  begin
                    Channel[curch]^[CurNote].Data := Channel[curch]^[CurNote].Data and $bfff;
                    if Channel[curch]^[CurNote].Data and $4000 <> 0 then
                       Channel[curch]^[CurNote].Data := Channel[curch]^[CurNote].Data and $c0ff;
                    Channel[curch]^[CurNote].Data :=Channel[curch]^[CurNote].Data  and $f0ff;
                    Channel[curch]^[CurNote].Data := Channel[curch]^[CurNote].Data  or (in1 shl 8);
                    CurVol := (Channel[curch]^[CurNote].Data and $ff00) shr 8;
                    dec(TPos.x);
                    if inson = 2 then if TPos.y < 49-step then inc(TPos.y,step)
                    else if faddr+48-bplace+step < maxnote then inc(Faddr,step);
                  end;
                SongChange := true;
                end
                else if (key = $3920) or (key = $342e) then
                 begin
                   Channel[curch]^[CurNote].Data := Channel[curch]^[CurNote].Data or $4000;
                   curvol := $40;
                 end;
              end;
        13,
        21,
        29,
        37,
        45,
        53,
        61,
        69,
        77  : if key and $ff in [32..122] then
              begin
                Channel[curch]^[CurNote].Data := Channel[curch]^[CurNote].Data xor $80;
                Cursno :=Channel[curch]^[CurNote].Data and $80;
                SongChange := true;
              end;

      end;



     case key of

   { Movement Keys }
 {Up}  $4800   : begin
                   if TPos.y > bplace+1 then dec(Tpos.y)
                   else if Faddr > 0 then dec(Faddr);
                   if MPos > 0 then dec(Mpos)
                   else if Maddr > 0 then dec(Maddr);

                 end;

 {Dn}  $5000   : begin
                   if TPos.y < 48 then inc(TPos.y)
                   else if faddr+47-bplace < maxnote then inc(Faddr);
                   if MPos < bplace-5 then inc(MPos)
                   else if Maddr+bplace-5 < maxnote then inc(Maddr);
                 end;

 {Lt}  $4b00   : begin
                   if TPos.x in [NWin[CurCh].x1+1..NWin[CurCh].x1+2,
                                 NWin[CurCh].x1+5..NWin[CurCh].x1+6]
                     then dec(TPos.x)
                   else
                   begin
                     if (curch > 0) and (tpos.x = NWin[CurCh].x1) then
                     begin
                       dec(Curch);
                       TPos.x := NWin[CurCh].x2;
                     end
                     else if TPos.x = NWin[CurCh].x1+4 then dec(Tpos.x,2);
                   end;
                   if (curch < 11) and (fmeta > 0) and (curch < fmeta)
                    then dec(fmeta);
                 end;

 {Rt}  $4d00   : begin
                   if TPos.x in [NWin[CurCh].x1..NWin[CurCh].x1+1,
                                 NWin[CurCh].x1+4..NWin[CurCh].x1+5]
                     then inc(TPos.x)
                   else
                   begin
                     if (curch < maxch) and (tpos.x = NWin[CurCh].x1+6) then
                     begin
                       inc(Curch);
                       TPos.x := NWin[CurCh].x1;
                     end
                     else if TPos.x = NWin[CurCh].x1+2 then inc(Tpos.x,2);
                   end;
                 end;

 {tab} $0f09  : if TPos.x+8 < NWin[maxch].x2 then begin
                                           inc(TPos.x,8);
                                           inc(curch);
                                if (curch > 11) and (fmeta < 9) and (curch > fmeta+10)
                                  then inc(fmeta,2);
                                      end
                else begin
                          TPos.x := NWin[maxch].x2;
                          curch := maxch;
                          fmeta := maxch-8;
                     end;

 {TAB} $0f00   : if Tpos.x -8 > 7 then
                   begin
                     dec(TPos.x,8);
                     dec(curch);
                     if (curch < 11) and (fmeta > 0) and (curch < fmeta)
                     then dec(fmeta,2);
                   end
                   else begin
                     TPos.x := 7;
                     curch := 0;
                     fmeta := 0;
                   end;

{PgDn} $5100   : if Tpos.y = 48 then
                            begin
                              if faddr < maxnote-96 + bplace +bplace then
                              begin
                                inc(Faddr,48-bplace);
                                Maddr := Faddr+47-bplace-(bplace-5);
                                Mpos  := bplace-5;
                              end
                              else begin
                                faddr := maxnote - 47 + bplace;
                                maddr := maxnote - bplace +5;
                              end;
                            end
                            else begin
                              TPos.y := 48;
                              MPos := bplace-5;
                              Maddr := Faddr + 47-bplace-(bplace-5);
                            end;
{PgUp} $4900   : if TPos.y > bplace+1 then
                            begin
                              TPos.y := bplace+1;
                              Mpos := 0;
                              MAddr := FAddr;
                            end
                            else begin
                              if faddr > 48-bplace then
                              begin
                                dec(Faddr,48-bplace);
                                MAddr := Faddr;
                                MPos := 0;
                              end
                              else begin
                                     Tpos.y := bplace+1;
                                     faddr := 0;
                                     Mpos := 0;
                                     Maddr := 0;
                                   end;
                            end;

{Home} $4700   : begin
                     TPos.x := 7;
                     curch := 0;
                     fmeta := 0;
                 end;

{End}  $4f00   : begin
                   TPos.x := NWin[maxch].x1;
                   curch := maxch;
                   fmeta := maxch-8;
                 end;

{^PDn} $7600   : begin
                   if curnote div segsize < maxnote div segsize then
                   begin
                     Faddr := ((Curnote div SegSize)+1)*(SegSize);
                     TPos.y:= bplace+1;
                     MPos := 0;
                     Maddr := Faddr;
                   end
                 end;
{^PUp} $8400   : begin
                   in1 := (Curnote div SegSize);
                   if Curnote mod SegSize = 0 then
                   begin
                    if in1 >= 1 then
                    begin
                      Faddr := (in1-1) * (SegSize);
                    end;
                   end
                   else Faddr := in1 * (SegSize);
                   TPos.y:= bplace+1;
                   MPos := 0;
                   MAddr := FAddr;
                 end;


     { Edit Keys }
{Entr} $1c0d   : insspace(curch,curnote,1);
{BSpc} $0e08   : begin
                   if TPos.y > bplace+1 then dec(Tpos.y)
                   else if Faddr > 0 then dec(Faddr);
                   delnote(curch,curnote-1,1);
                 end;
{Del}  $5300   : delnote(curch,CurNote,1);

   { Misc Keys }
{'}    $2b27   : inc(step);
{„}    $2884   : dec(step);
{s-'}  $2b2a   : inc(UMF.Tempo);
{s-„}  $288e   : dec(UMF.Tempo);
{/}    $352f   : if curoct > 0 then dec(curoct);
{*}    $372a   : if curoct < 7 then inc(curoct);
{+}    $4e2b   : inc(segsize,16);
{-}    $4a2d   : dec(segsize,16);

   { Function Keys }
 {Esc} $011b  : begin
                  curpos := 0;
                  repeat
                     BordWin(owin[1].x1,owin[1].y1,owin[1].x2,owin[1].y2,
                             $66,owin[1].col);
                     Check(0);
                     WrCol('New',owin[1].x1,owin[1].y1,TCol);
                     Check(1);
                     WrCol('Load',owin[1].x1,owin[1].y1+1,TCol);
                     Check(2);
                     WrCol('Save',owin[1].x1,owin[1].y1+2,TCol);
                     Check(3);
                     WrCol('Save As..',owin[1].x1,owin[1].y1+3,TCol);
                     Check(4);
                     WrCol('Song Setup',owin[1].x1,owin[1].y1+4,TCol);
                     WrCol('ÇÄÄÄÄÄÄÄÄÄÄÄ¶',owin[1].x1-1,owin[1].y1+5,$13);
                     Check(5);
                     WrCol('Setup PJAzZ',owin[1].x1,owin[1].y1+6,TCol);
                     Check(6);
                     WrCol('Exit to DOS',owin[1].x1,owin[1].y1+7,TCol);
                     PrVT;
                     key := getkey;
                     endo := false;
                     case key of
                       $4800  : dec(curpos);
                       $5000  : inc(curpos);
                       $1c0d  : case curpos of
                                  0 :
                                        if PrQuestion('Lose Current Song?',$03) = 1 then
                                        begin
                                          NewSong;
                                          goto 2;
                                        end;
                                  2 : if PrQuestion('Save Current Song?',$03) = 1 then SaveCurSong;
                                  1 : loadsong;
                                  3 : SaveSong;
                                  4 : SetupSong;
                                  5 : {SetupPJAzZ};
                                  6 : if (songchange) then
                                      begin
                                      case PrQuestion('Save Changes to '+UMFName+'?',$03) of
                                        2  : goto 1;
                                        1  : begin
                                               SaveCurSong;
                                               goto 1;
                                             end;
                                      end;
                                      end
                                      else if PrQuestion('Want to Exit?',$03) = 1 then goto 1;
                                end;
                     end;
                     if curpos =255 then curpos := 6
                     else if curpos = 7 then curpos := 0;
                  until (key = $011b) or (endo);
                end;
       $3b00   : sounds;
       $3c00   : startPlay;
       $3d00   : startPlay2;
       $3e00   : OrderEdit;
       $3f00   : loadsong;
       $4000   : saveCurSong;
       $5900   : saveUMF(copy(umfname,1,length(umfname)-4)+'.UMF');
       $4100   : saveSong;
       $4200   : SetupSong;
       $4300   : {SetupPJazZ};
       $4400   : {HelpPJazZ};


   { Rythm Commands }
{A-r}  $1300   : bdval := bdval xor 32;
{A-1}  $7800   : bdval := bdval xor 1;
{A-2}  $7900   : bdval := bdval xor 2;
{A-3}  $7a00   : bdval := bdval xor 4;
{A-4}  $7b00   : bdval := bdval xor 8;
{A-5}  $7c00   : bdval := bdval xor 16;

   { Area Commands }

       $310e   : channel[curch]^[curnote].fmeta := nil;
{A-a}  $1e01   : begin
                   AreaOn := not AreaOn;
                   AreaOn2 := true;
                   if AreaOn then
                   begin
                     Area.x1 := CurCh;
                     Area.y1 := CurNote;
                   end;
                 end;
{^c}   $2e03   : begin
                  AreaOn := false;
                  ClipBMax.x := Area.x2-Area.x1+1;
                  ClipBMax.y := Area.y2-Area.y1+1;
                  if (ClipbMax.y <= MaxArea) then
                   for in1 := 0 to ClipbMax.x-1 do
                     for in2 := 0 to ClipbMax.y-1 do
                       ClipB[in1,in2] := Channel[Area.x1+in1]^[Area.y1+in2];
                 end;
{^d}   $2004   : if getkey = $2004 then
                 begin
                   for in1 := Area.x1 to Area.x2 do
                   if in1 <= maxch then
                     for in2 := Area.y1 to Area.y2 do
                       if in2 <= maxnote then
                       begin
                         Channel[in1]^[in2] := EmptyNote;
                         delameta(in1,in2);
                       end;
                   SongChange := true;
                 end;
{^z}   $2c1a   : begin
                  for in1 := 0 to ClipbMax.x-1 do
                  begin
                  InsSpace(curch+in1,curnote,ClipBmax.y);
                   if curch+in1 <= maxch then
                     for in2 := 0 to ClipbMax.y-1 do
                       if curnote+in2 <= maxnote then
                       begin
                         Channel[curch+in1]^[curnote+in2].cmd := ClipB[in1,in2].cmd;
                         Channel[curch+in1]^[curnote+in2].data := ClipB[in1,in2].data;
                         CurMEta := ClipB[in1,in2].FMeta;
                         while CurMeta <> nil do
                         begin
                           Channel[curch+in1]^[curnote+in2].Fmeta :=
                             newmeta(curch+in1,curnote+in2,Curmeta^.cmd,
                                     Curmeta^.data);
                           curmeta := curmeta^.next;
                         end;
                       end;
                  end;
                  SongChange := true;
                 end;
{^x}   $2d18   : begin
                  for in1 := 0 to ClipbMax.x-1 do
                   if curch+in1 <= maxch then
                     for in2 := 0 to ClipbMax.y-1 do
                       if curnote+in2 <= maxnote then
                       begin
                         delameta(curch+in1,curnote+in2);
                         Channel[curch+in1]^[curnote+in2].cmd := ClipB[in1,in2].cmd;
                         Channel[curch+in1]^[curnote+in2].data := ClipB[in1,in2].data;
                         CurMEta := ClipB[in1,in2].FMeta;
                         while CurMeta <> nil do
                         begin
                           Channel[curch+in1]^[curnote+in2].Fmeta :=
                             newmeta(curch+in1,curnote+in2,Curmeta^.cmd,
                                     Curmeta^.data);
                           curmeta := curmeta^.next;
                         end;
                       end;

                 SongChange := true;
                 end;
{^q}   $1011   : begin
                   Area := EmptyArea;
                   Areaon2 := false;
                 end;

{^s}   $1f13   : begin
                   AreaOn2 := true;
                   Area.y1 := segsize*(curnote div segsize);
                   Area.y2 := Area.y1 + segsize -1;
                   if ctrls then
                   begin
                     Area.x1 := 0;
                     Area.x2 := maxch;
                     ctrls := false;
                   end
                   else
                   begin
                     Area.x1 := curch;
                     Area.x2 := Area.x1;
                     ctrls := true;
                   end;
                 end;

{}    $2915   : MetaEdit;
     end;

     soundkeys(key);
     if (soundkey <> lskey) and (soundkey <> 255) then
     begin
          if Channel[CurCH]^[CurNote].Fmeta^.cmd = 1 then
          begin
            delmeta(curch,curnote,1);
            Channel[CurCH]^[CurNote].Fmeta := newmeta(curch,curnote,1,soundkey);
          end
          else changemeta(curch,curnote,1,soundkey);
          CurIns[CurCh] := soundkey;
          SetSound(CurCh);
          lskey := soundkey;
     end;
     access($bd,bdval,bport);
     CurNote := faddr + Tpos.y - (bplace + 1);
     if AreaOn then
     begin
       Area.x2 := CurCh;
       Area.y2 := CurNote;
       if area.y2 - area.y1 > $ff then area.y2 := area.y1+$ff;
     end;
     if Channel[curch]^[CurNote].Data and $ff00 > $3f00 then
     begin
       Channel[curch]^[CurNote].Data := Channel[curch]^[CurNote].Data or $4000;
     end;
     if curvol > $3f00 then curvol := $40;
   end; { case of inson }
     If Random(255) = 10 then ErrCode := random(9)+4;
     until false;
1:
     for in1 := 0 to maxch do soundoff(in1);
     delay(100);
     soundinit;
     textmode(co80);
     textbackground(0);
     textcolor(7);
     clrscr;
     for in1 := 0 to 15 do Pal(in1,OrgPal[in1].r,OrgPal[in1].g,OrgPal[in1].b);
     writeln('You Have Been Using PaRAlleL JAzZ v'+ver+'   (C) Don Unonen of PaRAlleL NiGhtMaReS');
     SetPIT($ffff);
     setintvec($1c,int1csave);
     for in1 := 0 to maxch do soundoff(in1);
     delay(100);
     soundinit;
     Release(HeapSt);

end.
{
ºúú 0000º000-000º000-000º000-000º000-000º000-000º000-000º000-000º000-000º