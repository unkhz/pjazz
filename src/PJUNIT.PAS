unit PJUnit;
                                { nots means: 'This won't be saved' }

interface
uses dos;
const
     maxnote = $4fe;
     maxord  = $48;
     maxch   = 8;
     maxins  = 255;
     maxoch  = 3;
     CurUMFVer = 1;
type
    UMFDataTYPE = record
                        title         : string[32];    {Song's name }
                        tempo,
                        ver,InsNum    : Byte; { tempo,speed,version,
                                                number of instruments }

                  end;

    MetaPtr  = ^METAType;
    METAType = record
                     Cmd : Byte;
                     Data: byte;
                     next: METaPtr;
               end;

    NoteTYPE =  record
                         Cmd          : Byte; { MIDI-Note }
                         Data         : Word; { Note data notalwayss}
                         fmeta        : METAPtr;
                end;

    OrderTYPe = record
                  a1,a2 :word;  {a1:fromaddr,a2:toaddr}
                  chs   :array[0..8] of boolean;
                end;

    ByteSet = set of byte;

    channelptr = ^channeltype;
    channelType = array[0..maxnote] of NoteType;
const
     WData :ByteSet = [];                { set of word-data MIDI-cmds }
     BData :ByteSet = [1,3];             { set of byte-data MIDI-cmds }
     NData :ByteSet = [0];               { set of nodata MIDI-Cmds }
     bport = $388;                       { both channels output port }
     lport = $220;                       { left channel output port }
     rport = $222;                       { right channel output port }
     NotFreqs : array[1..12] of word =   { frequencies to notes c - b }
                  ($156,$16b,$181,$198,$1b0,$1ca,
                   $1e5,$202,$220,$241,$263,$287);
     ChNums   : array[0..8] of byte =    { channels for accessing }
                  (0,1,2,8,9,10,16,17,18);
     EmptyNote : NoteType = (Cmd:0; Data:$4000;FMeta:nil);
     EmptyMeta : metaType = (Cmd:0; Data:0;next:nil);
     EmptyOrder: OrderTYPE= (a1:0; a2:0; chs:(false,false,false,false,false,
                                              false,false,false,false));

var
   UMF              : UMFDataType;  { UMF-file data }
   channel          : array[0..maxch] of channelptr;   { Channelblock }
   Order            : array[0..maxoch,0..maxord] of ordertype; { orderblock }
   Ins              : array[0..maxins,0..15] of byte;  { Instrument ptr }
   CurIns           : array[0..maxch] of byte;  { current ins of each ch }
   CurMeta          : MetaPtr;
   ErrCode          : Byte;         { error occured and errcode <> 0 }
   CurOct           : Byte;         { current octave }
   spress           : boolean;
   scount           : byte;
   soundkey         : byte;
   segsize          : byte;              { current segment size }

procedure access(reg,value:byte;prt:word);
   { access the sound registers }
procedure SoundInit;
procedure SoundInit2;
   { init the sound registers }
function InsNum:byte;
function lastorder:word;
procedure SaveUMF(name:string);
(*procedure LoadUMF(path:String);
   { Loads an UMF-file }
procedure SaveUMF(name:String);
   { Saves the UMF-file }
*)
function NextMETA(location:METAPtr;step:byte):METAPtr;
   { Moves in array }
function NewMeta(ch:byte;nt:word;cm:byte;dt:word):MetaPtr;
   { returns a new Meta-shit }
procedure delMeta(ch:byte;nt:word;n:byte);
   { dels one meta }
procedure delaMeta(ch:byte;nt:word);
   { deletes all meta }
procedure Changemeta(ch:byte;nt:word;cm:byte;dt:byte);
   { Changes all specified meta-commands }
function SearchMeta(ch:byte;nt:word;cm:byte):byte;
   { searches for specified meta-cmd }
procedure delnote(ch:byte;nt,n:word);
   { Deletes a note }
procedure InsSpace(ch:byte;nt,n:word);
   {Inserts an empty note }
function LastNote:Word;
   { returns the last used note }
function CheckKeys(k:word):word;
   { handles notekeys }
procedure soundkeys(k:word);
   { handles instrument changing keys }
procedure soundoff(ch:byte);
   { guess }
procedure savejzz(nam:string);
   { saves as JZZ-file }
procedure loadjzz(nam:string);
   { loads as JZZ-file }
procedure setsound(ch:byte);
   { sets current instrument on ch }
procedure SetPIT(n:word);
   { sets programmable Interval Timer to n}
Implementation


procedure access(reg,value:byte;prt:word); Assembler;
          asm
             mov dx,prt
             mov al,reg
             out dx,al
             in  al,dx
             in  al,dx
             in  al,dx
             in  al,dx
             in  al,dx
             in  al,dx
             inc dx
             mov al,value
             out dx,al
             dec dx
             in  al,dx
             in  al,dx
             in  al,dx
             in  al,dx
             in  al,dx
             in  al,dx
             in  al,dx
             in  al,dx
             in  al,dx
             in  al,dx
             in  al,dx
             in  al,dx
             in  al,dx
             in  al,dx
             in  al,dx
             in  al,dx
             in  al,dx
             in  al,dx
             in  al,dx
             in  al,dx
             in  al,dx
             in  al,dx
             in  al,dx
             in  al,dx
             in  al,dx
             in  al,dx
             in  al,dx
             in  al,dx
             in  al,dx
             in  al,dx
             in  al,dx
             in  al,dx
             in  al,dx
             in  al,dx
             in  al,dx
          end; { access }

procedure SoundInit2;
          var
             i1,i2:integer;
          begin
               spress := false;
               soundkey := 0;
               for i1 := 0 to maxch do
               begin
                 Channel[i1] := new(channelptr);
                 for i2 := 0 to maxnote do
                   Channel[i1]^[i2] := EmptyNote;
               end;
               for i1 := 0 to maxoch do
                 for i2 := 0 to maxord do
                   order[i1,i2] := emptyorder;
          end;
procedure SoundInit;
          var i1:byte;
          begin
               ErrCode := 0;
               i1 := 0;
               repeat
                     inc(i1);
                     access(i1,0,bport);
               until i1 = $f5;
          end; { SoundInit }
function InsNum;
var i1,i2,tins:byte;
    found:boolean;
begin
     tins := 0;
     for i1 := 0 to maxins do
     begin
       i2 := 0;
       while i2 in[0..15] do
       begin
         if Ins[i1,i2] <> 0 then found := true;
         inc(i2);
       end;
       if found then tins := i1;
       found := false;
     end;
     InsNum := tins;
end;

function lastorder;
var i1,i2 :word;
begin
   i2 := 0;
   for i1 := 0 to maxord do
     if (order[0,i1].a1 <> 0) or (order[0,i1].a2 <> 0) then i2 := i1;
   lastorder := i2;
end;

procedure SaveUMF(name:string);
var
   i1,i2,i3,i4 : word;
   a1,a2 : word;
   f     : text;
   Inss  : byte;
   chiu  : word;
   twait : word;
   tmeta : MetaPtr;
   lnote,lord : word;
label 1,2;
begin
     lnote := lastnote;
     lord  := lastorder;
     inss := insnum;
     Assign(f,name);
     ReWrite(f);
     write(f,'UMF'+chr(CurUMFVer));
     i1 := ((Inss+1) * 16) + $28;
     write(f,chr(i1 shr 8));
     write(f,chr(i1 and $ff));
     write(f,chr(UMF.Tempo));
     write(f,chr(inss+1));
     for i1 := 1 to length(umf.title) do                 { song title }
       write(f,copy(UMF.Title,i1,1));
     for i1 := 1 to 32-length(umf.title) do
       write(f,' ');
     for i1 := 0 to inss do               { sound block }
       for i2 := 0 to 15 do
         write(f,chr(Ins[i1,i2]));

     { muzak plock }

  for i1 := 0 to 8 do
  begin
   twait := 1;
   for i2 := 0 to lord do
   begin
     i3 := 0;
     repeat inc(i3); until (order[i3-1,i2].chs[i1]) or (i3-1 = 4);
     dec(i3);
     if i3 > 1 then
     begin
       write(f,chr(twait));
       write(f,chr(2));
       twait := 0;
     end;
     if i3 = 4 then
     begin
       twait := twait + order[0,i2].a2 - order[0,i2].a1+1;
       goto 2;
     end;
     a2 := 0;
     for i4 := 0 to order[0,i2].a2 - order[0,i2].a1 do
     begin
       a1 := order[i3,i2].a1 + a2;
       tmeta := channel[i1]^[a1].FMEta;            { Meta save }
       while tmeta <> nil do
       begin
         write(f,chr(twait and $ff));
         twait := 0;
         write(f,chr(tmeta^.cmd + 3));
         write(f,chr(TMeta^.data));
         tmeta := tmeta^.next;
       end;

       if channel[i1]^[a1].cmd in [1,2] then      { Note Save }
       begin
         write(f,chr(twait and $ff));
         twait := 1;
         write(f,chr(channel[i1]^[a1].cmd));
         if channel[i1]^[a1].cmd = 1 then
         begin
           write(f,chr(channel[i1]^[a1].data shr 8));
           write(f,chr(channel[i1]^[a1].data and $ff));
         end;
       end
       else
       begin
         inc(twait);
         if twait > $ff then
         begin
           write(f,chr($ff));
           write(f,chr(3));
           dec(twait,$ff);
         end;
       end;

1:
     if a1 < order[i3,i2].a2 then inc(a2) else a2 := 0;
     end;
2:
   end;
   write(f,chr(twait and $ff));
   write(f,chr($ff));
  end;
  close(f);
end;

function NextMETA(location:METAPtr;step:byte):METAPtr;
var i2:integer;
begin
     for i2 := 1 to step do
       if Location <> nil then Location := Location^.Next;
     NextMeta := Location;
end;

function NewMeta(ch:byte;nt:word;cm:byte;dt:word):MetaPtr;
var NMeta:MetaPtr;
begin
     nmeta := new(metaptr);
     nmeta^.Cmd := cm;
     NMeta^.Data:= dt;
     NMeta^.next := Channel[Ch]^[Nt].FMeta;
     NewMeta := NMeta;
end;

procedure delMeta(ch:byte;nt:word;n:byte);
var i1:byte;
    tmp:metaptr;
begin
     tmp := Channel[Ch]^[Nt].Fmeta^.next;
     if (Channel[Ch]^[Nt].Fmeta <> nil) then
     begin
       if tmp <> nil then
       begin
         dispose(Channel[Ch]^[Nt].Fmeta);
         Channel[Ch]^[Nt].Fmeta := tmp;
       end
       else begin
         dispose(Channel[Ch]^[Nt].Fmeta);
         Channel[Ch]^[Nt].Fmeta := nil;
       end;
     end;
end;

procedure delaMeta(ch:byte;nt:word);
var temp : metaptr;
begin
     temp := Channel[ch]^[nt].fmeta;
     while temp <> nil do
     begin
       delmeta(ch,nt,1);
       temp := Channel[ch]^[nt].fmeta;
     end;

end;


procedure changeMeta(ch:byte;nt:word;cm:byte;dt:byte);
var i1:byte;
    dmeta:metaptr;
    next,prev :metaptr;
    done :boolean;
begin
     done := false;
     dmeta := Channel[Ch]^[Nt].Fmeta;
     while (DMeta <> nil) do
     begin
       if dmeta^.cmd = cm then
       begin
         dmeta^.data := dt;
         done := true;
       end;
       dmeta := dmeta^.next;
     end;
     if not done then Channel[ch]^[nt].Fmeta := newmeta(ch,nt,cm,dt);
end;

function SearchMeta(ch:byte;nt:word;cm:byte):byte;
var
    dmeta:metaptr;
    done :boolean;
begin
     dmeta := Channel[Ch]^[Nt].Fmeta;
     while (DMeta <> nil) do
     begin
       if dmeta^.cmd = cm then
       begin
         searchmeta := dmeta^.data;
         done := true;
       end;
       dmeta := dmeta^.next;
     end;
     if not done then searchmeta := 0;
end;

procedure delnote(ch:byte;nt,n:word);
var i1:word;
begin
     delameta(ch,nt);
     for i1 := nt to maxnote-n  do
       Channel[ch]^[i1] := Channel[ch]^[i1+n];
     Channel[ch]^[maxnote].Cmd := 0;
     Channel[ch]^[maxnote].Data:= 0;
     Channel[ch]^[maxnote].FMeta:= nil;
end;

procedure InsSpace(ch:byte;nt,n:word);
var i1:word;
begin
     delnote(ch,maxnote,1);
     for i1 := maxnote downto nt+n do
     begin
       Channel[ch]^[i1] := Channel[ch]^[i1-n];

     end;
     Channel[ch]^[nt].Cmd := 0;
     Channel[ch]^[nt].Data:= 0;
     Channel[ch]^[nt].FMeta:= nil;
end;

function LastNote:Word;
var lnot ,i1,i2: Word;
begin
     lnot := 0;
     for i1 := 0 to maxch do
      for i2 := 0 to maxnote do
        if (Channel[i1]^[i2].cmd <> 0) and (i2 > lnot) then lnot := i2;
     LastNote := LNot;
end;

function CheckKeys(k:word):word;
var i1:word;
begin
       i1 := 0;
       case k of
            $2c7a   : i1 := 1 or (CurOct shl 4);
            $1f73   : i1 := 2 or (CurOct shl 4);
            $2d78   : i1 := 3 or (CurOct shl 4);
            $2064   : i1 := 4 or (CurOct shl 4);
            $2e63   : i1 := 5 or (CurOct shl 4);
            $2f76   : i1 := 6 or (CurOct shl 4);
            $2267   : i1 := 7 or (CurOct shl 4);
            $3062   : i1 := 8 or (CurOct shl 4);
            $2368   : i1 := 9 or (CurOct shl 4);
            $316e   : i1 := 10 or (CurOct shl 4);
            $246a   : i1 := 11 or (CurOct shl 4);
            $326d   : i1 := 12 or (CurOct shl 4);
            $332c   : i1 := 1 or (CurOct +1) shl 4;
            $266c   : i1 := 2 or (CurOct +1 ) shl 4;
            $342e   : i1 := 3 or (CurOct +1 ) shl 4;
            $2794   : i1 := 4 or (CurOct +1 ) shl 4;
            $352d   : i1 := 5 or (CurOct +1 ) shl 4;

            $1071   : i1 := 1 or (CurOct +1 ) shl 4;
            $0332   : i1 := 2 or (CurOct +1 ) shl 4;
            $1177   : i1 := 3 or (CurOct +1 ) shl 4;
            $0433   : i1 := 4 or (CurOct +1 ) shl 4;
            $1265   : i1 := 5 or (CurOct +1 ) shl 4;
            $1372   : i1 := 6 or (CurOct +1 ) shl 4;
            $0635   : i1 := 7 or (CurOct +1 ) shl 4;
            $1474   : i1 := 8 or (CurOct +1 ) shl 4;
            $0736   : i1 := 9 or (CurOct +1 ) shl 4;
            $1579   : i1 := 10 or (CurOct +1 ) shl 4;
            $0837   : i1 := 11 or (CurOct +1 ) shl 4;
            $1675   : i1 := 12 or (CurOct +1 ) shl 4;
            $1769   : i1 := 1 or (CurOct +2 ) shl 4;
            $0a39   : i1 := 2 or (CurOct +2 ) shl 4;
            $186f   : i1 := 3 or (CurOct +2 ) shl 4;
            $0b30   : i1 := 4 or (CurOct +2 ) shl 4;
            $1970   : i1 := 5 or (CurOct +2 ) shl 4;

            $2c5a   : i1 := 1 or (CurOct-1 ) shl 4;
            $1f53   : i1 := 2 or (CurOct-1 ) shl 4;
            $2d58   : i1 := 3 or (CurOct-1 ) shl 4;
            $2044   : i1 := 4 or (CurOct-1 ) shl 4;
            $2e43   : i1 := 5 or (CurOct-1 ) shl 4;
            $2f56   : i1 := 6 or (CurOct-1 ) shl 4;
            $2247   : i1 := 7 or (CurOct-1 ) shl 4;
            $3042   : i1 := 8 or (CurOct-1 ) shl 4;
            $2348   : i1 := 9 or (CurOct-1 ) shl 4;
            $314e   : i1 := 10 or (CurOct-1 ) shl 4;
            $244a   : i1 := 11 or (CurOct-1 ) shl 4;
            $324d   : i1 := 12 or (CurOct-1 ) shl 4;
            $333b   : i1 := 1 or (CurOct shl 4);
            $264c   : i1 := 2 or (CurOct shl 4);
            $343a   : i1 := 3 or (CurOct shl 4);
            $2799   : i1 := 4 or (CurOct shl 4);
            $355f   : i1 := 5 or (CurOct shl 4);

            $1051   : i1 := 1 or (CurOct +2 ) shl 4;
            $0322   : i1 := 2 or (CurOct +2 ) shl 4;
            $1157   : i1 := 3 or (CurOct +2 ) shl 4;
            $0423   : i1 := 4 or (CurOct +2 ) shl 4;
            $1245   : i1 := 5 or (CurOct +2 ) shl 4;
            $1352   : i1 := 6 or (CurOct +2 ) shl 4;
            $0625   : i1 := 7 or (CurOct +2 ) shl 4;
            $1454   : i1 := 8 or (CurOct +2 ) shl 4;
            $0726   : i1 := 9 or (CurOct +2 ) shl 4;
            $1559   : i1 := 10 or (CurOct +2 ) shl 4;
            $082f   : i1 := 11 or (CurOct +2 ) shl 4;
            $1655   : i1 := 12 or (CurOct +2 ) shl 4;
            $1749   : i1 := 1 or (CurOct +3 ) shl 4;
            $0a29   : i1 := 2 or (CurOct +3 ) shl 4;
            $184f   : i1 := 3 or (CurOct +3 ) shl 4;
            $0b3d   : i1 := 4 or (CurOct +3 ) shl 4;
            $1950   : i1 := 5 or (CurOct+3 ) shl 4;
       end;
       CheckKeys := i1;
end;
procedure soundkeys(k:word);
var i2:byte;
begin

  i2 := k and $ff -$30;
  if (k shr 8 in [$47..$52]) and (i2 in [0..9]) then
  begin
    if soundkey = 255 then soundkey := 0;
    if (spress) then
    begin
      soundkey := (soundkey * 10) and $ff;
      spress := false;
    end
    else
    begin
      soundkey := 0;
      spress := true;
    end;
    soundkey := soundkey + i2;
    scount := 64;
  end
  else soundkey := 255;
end;
procedure soundoff(ch:byte);
          var prt:word;
          begin
               if ch > 8 then ch := ch-9;
               prt := bport;
               access($a0+ch,$00,prt);
               access($b0+ch,$00,prt);
          end;{soundoff}

procedure savejzz(nam:string);
var f:file;
    i1,i2:longint;
    bi   :byte;
    fohh : word;
    TMeta:MetaPtr;
    TempOrder:array[0..2,0..maxord] of ordertype; { orderblock }
const
     s1:string[3] = 'JZZ';
     nul:char = chr(0);
begin
{$I-}
     errCode := 0;
     assign(f,nam);
     rewrite(f,1);
     fohh := lastnote;
     blockwrite(f,s1,sizeof(s1));
     blockwrite(f,fohh,2);
     if ioresult = 0 then
     begin
     for i1 := 0 to maxch do
       for i2 := 0 to fohh do
         blockwrite(f,channel[i1]^[i2],sizeof(channel[i1]^[i2]));

     for i1 := 0 to maxch do
       for i2 := 0 to fohh do
         if channel[i1]^[i2].FMEta <> nil then
         begin
           TMeta := channel[i1]^[i2].FMEta;
           while TMEta <> nil do
           begin
             blockwrite(f,tmeta^.cmd,sizeof(tmeta^.cmd));
             bi := tmeta^.data and $ff;
             blockwrite(f,bi,sizeof(bi));
             TMEta := tMEta^.next;
           end;
           Blockwrite(f,nul,sizeof(tmeta^.cmd));
         end
         else Blockwrite(f,nul,sizeof(tmeta^.cmd));

     blockwrite(f,Order,sizeof(order));
     blockwrite(f,ins,sizeof(ins));
     blockwrite(f,curins,sizeof(curins));
     blockwrite(f,umf,sizeof(umf));
     blockwrite(f,SegSize,sizeof(SegSize));
     close(f);
     end
     else ErrCode := 2; {Bad Filename}
{$I+}
end;
procedure loadjzz(nam:string);
var f:file;
    i1,i3:longint;
    i2:word;
    s1:string[3];
    TMeta:MetaPtr;
    ch:char;
    TempOrder:array[0..2,0..maxord] of ordertype; { orderblock }
const
     nul:char = chr(0);
begin
{$I-}

     ErrCode := 0;
     assign(f,nam);
     reset(f,1);
     if ioresult = 0 then
     begin
     blockread(f,s1,sizeof(s1));
     if s1 = 'JZZ' then
     begin
     blockread(f,i2,2);
     for i1 := 0 to maxch do
       for i3 := 0 to i2 do
       blockread(f,channel[i1]^[i3],sizeof(channel[i1]^[i3]));

      for i1 := 0 to maxch do
       for i3 := 0 to i2 do
       begin
         blockread(f,ch,sizeof(tmeta^.cmd));
         if ord(ch) <> 0 then
         begin
         channel[i1]^[i3].FMEta := nil;
          while ord(ch) <> 0 do
           begin
             TMeta^.cmd := ord(ch);
             blockread(f,tmeta^.data,sizeof(tmeta^.data));

             channel[i1]^[i3].FMEta := newmeta(i1,i3,TMEta^.cmd,TMEta^.data);
             blockread(f,ch,sizeof(tmeta^.cmd));
           end;
         end
       end;
     blockread(f,Order,sizeof(order));

     blockread(f,ins,sizeof(ins));
     blockread(f,curins,sizeof(curins));
     blockread(f,umf,sizeof(umf));
     blockread(f,SegSize,sizeof(SegSize));
     for i1 := 0 to maxch do setsound(i1);
     end
     else ErrCode := 3;  {Unknown File Format}
     close(f);
     end
     else ErrCode := 1; {file not found}
{$I+}
end;

procedure setsound(ch:byte);
begin
               access($20+chnums[ch],ins[curins[ch],0],bport);
               access($23+chnums[ch],ins[CurIns[Ch],1],bport);
               access($40+chnums[ch],ins[CurIns[Ch],2],bport);
               access($43+chnums[ch],ins[CurIns[Ch],3],bport);
               access($60+chnums[ch],ins[CurIns[Ch],4],bport);
               access($63+chnums[ch],ins[CurIns[Ch],5],bport);
               access($80+chnums[ch],ins[CurIns[Ch],6],bport);
               access($83+chnums[ch],ins[CurIns[Ch],7],bport);
               access($e0+chnums[ch],ins[CurIns[Ch],8],bport);
               access($e3+chnums[ch],ins[CurIns[Ch],9],bport);
               access($c0+ch,ins[CurIns[Ch],10],bport);
end;
procedure SetPIT(n:word); assembler;
     asm
	   cli
	   mov	al,00110110b
	   out	43h,al
	   mov	cx,n
	   mov	al,cl
	   out	40h,al
	   mov	al,ch
	   out	40h,al
	   sti
     end;

end.




