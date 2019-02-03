unit UMFPlay;


interface

uses dos;

const
     bport = $388;
     NotFreqs : array[1..12] of word =   { frequencies to notes c - b }
                  ($156,$16b,$181,$198,$1b0,$1ca,
                   $1e5,$202,$220,$241,$263,$287);
     ChNums   : array[0..8] of byte =    { channels for accessing }
                  (0,1,2,8,9,10,16,17,18);
type
    SlideRec = record
                 on    :boolean;
                 dir   :byte;
                 fr    :word;
                 count :byte;
                 val   :byte;
               end;

var
   Ins        : array[0..$ff,0..15] of byte;
   CurIns     : array[0..8] of byte;
   Channel    : array[0..8] of pointer;
   MuteCh     : array[0..8] of boolean;
   Memsize    : array[0..8] of word;
   tempo      : byte;
   INum       : byte;
   Title      : String[32];
   ErrCode    : byte;
   PlayOn     : boolean;
   Pl_Count   : word;
   Pl_Pos     : array[0..8] of word;
   Pl_Wait    : array[0..8] of byte;
   int1csave,hs  : pointer;
   bdval      : byte;
   Sl       : array[0..8] of SLideREC;
   Dl       : array[0..8] of record on:boolean; val:byte; nt:word; end;
   DlCount  : byte;

procedure access(reg,value:byte);
   { access the sound registers }
procedure SetPIT(n:word);
   { sets programmable Interval Timer to n}
procedure RemUMF;
   { removes UMF-file from memory }
procedure InitSound;
   { sets up soundstuff }
procedure DoneSound;
   { returns stuff to normal }
procedure ResetSong;
   { sets up song stuff }
procedure LoadUMF(name:string);
   { Loads UMF-file to memory }
procedure setsound(ch:byte);
   { puts on CurIns of channel }
procedure PlayHandler; Interrupt;
   { Handles playing }
implementation

procedure access(reg,value:byte); Assembler;
          asm
             mov dx,bport
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

procedure RemUMF;
var i1:byte;
begin
  for i1 := 0 to 8 do freemem(channel[i1],memsize[i1]);
end;
procedure InitSound;
var i1:byte;
begin
  for i1 := 1 to $f5 do access(i1,0);
  for i1 := 0 to 8 do
  begin
    Pl_Pos[i1] := 1;
    MemSize[i1] := 0;
    Pl_Wait[i1] := 0;
  end;
  bdval := 0;
  GetIntVec($1c,int1csave);
  SetIntVec($1c,addr(PlayHandler));
  SetPIT($2000);
end;

procedure donesound;
var i1:byte;
begin
  for i1 := 1 to $f5 do access(i1,0);
  SetPIT($ffff);
  playon := false;
  SetIntVec($1c,int1csave);
  remumf;
end;

procedure ResetSong;
var i1 :word;
begin
     for i1 := 0 to 8 do
     begin
       MuteCh[i1] := false;
       Pl_Pos[i1] := 1;
       Pl_Wait[i1] := mem[seg(channel[i1]^):0];
     end;
     Pl_Count := 0;
     bdval := 0;
end;
procedure LoadUMF;
var
   i1,i2,i3,i4 : word;
   check : string[3];
   ch : char;
   MBOfs :word;
   MBChs :array[0..8] of word;
   f     : text;
begin
  ErrCode := 0;
  assign(f,name);
  if IoResult = 0 then
  begin
    check := '';
    Reset(f);
    read(f,ch);               { 'UMF' check }
    check := check + ch;
    read(f,ch);
    check := check + ch;
    read(f,ch);
    check := check + ch;
    if check = 'UMF' then
    begin
      read(f,ch);             { Version Number }
      read(f,ch);             { Music Block offset }
      MBOfs := ord(ch) shl 8;
      read(f,ch);
      inc(MBOfs,ord(ch));
      read(f,ch);
      tempo := ord(ch);       { Tempo }
      read(f,ch);
      INum  := ord(ch);       { of Instruments, Number }
      for i1 := 1 to 32 do
      begin
        read(f,ch);           { Music Title }
        Title := Title + ch;
      end;
      for i1 := 0 to INum-1 do
        for i2 := 0 to 15 do
        begin
          read(f,ch);         { Instrument Block }
          Ins[i1,i2] := ord(ch);
        end;
      i3 := MBOfs;
      for i1 := 0 to 8 do     { Music Block Size Read}
      begin
       repeat
        read(f,ch);
        i4 := ord(ch);
        read(f,ch);
        inc(i3,2);
        i2 := ord(ch);
        if i2 = 1 then
        begin
          read(f,ch);
          read(f,ch);
          inc(i3,2);
        end;
        begin
         if (i2 = 0) or (i2 > 3) and (i2 <> $ff) then
         begin
           read(f,ch);
           inc(i3);
         end;
        end;
       until i2 = $ff;
      MBChs[i1] := i3;
      end;
      close(f);
      Reset(f);
        memsize[0] := MBChs[0] - MBofs-1;
        GetMem(Channel[0],MBChs[0] - MBofs ); { Music Block }
        for i1 := 1 to MBOfs do read(f,ch);
        for i2 := 0 to MBChs[0] - MBofs -1 do
        begin
          read(f,ch);
          mem[seg(Channel[0]^):i2] := ord(ch);
        end;
      for i1 := 1 to 8 do
      begin
        Memsize[i1] := MBChs[i1] - MBChs[i1-1]-1;
        GetMem(Channel[i1],MBChs[i1] - MBChs[i1-1]);
        for i2 := 0 to MBChs[i1] - MBChs[i1-1]-1 do
        begin
          read(f,ch);
          mem[seg(Channel[i1]^):i2] := ord(ch);
        end;
      end;
    end
    else ErrCode := 3;
 end
 else ErrCode := 1;
 close(f);
 ResetSong;
end;

procedure setsound(ch:byte);
begin
               access($20+chnums[ch],ins[curins[ch],0]);
               access($23+chnums[ch],ins[CurIns[Ch],1]);
               access($40+chnums[ch],ins[CurIns[Ch],2]);
               access($43+chnums[ch],ins[CurIns[Ch],3]);
               access($60+chnums[ch],ins[CurIns[Ch],4]);
               access($63+chnums[ch],ins[CurIns[Ch],5]);
               access($80+chnums[ch],ins[CurIns[Ch],6]);
               access($83+chnums[ch],ins[CurIns[Ch],7]);
               access($e0+chnums[ch],ins[CurIns[Ch],8]);
               access($e3+chnums[ch],ins[CurIns[Ch],9]);
               access($c0+ch,ins[CurIns[Ch],10]);
end;

procedure PlayHandler;
var
   i1,i2,i3,i4,cm,cdata,fre : word;
   slide,dela :byte;
label 1,2;
begin
  slide := 0;
  if playon then
  begin
    if Pl_Count = 0 then
    begin
      for i2 := 0 to 8 do
      begin
        if Pl_Wait[i2] in [0,1] then
        begin
1:
         if not MuteCh[i2] then
         begin
          cm    := mem[seg(channel[i2]^):Pl_Pos[i2]];
          inc(Pl_Pos[i2]);
          case cm of
            1   : begin
                    cdata := mem[seg(channel[i2]^):Pl_pos[i2]] shl 8;
                    inc(Pl_Pos[i2]);
                    cdata := cdata + mem[seg(channel[i2]^):Pl_pos[i2]];
                    inc(Pl_Pos[i2]);
                  end;
            2,3 : cdata := 0;
            4..$fe :begin
                      cdata := mem[seg(channel[i2]^):Pl_Pos[i2]];
                      inc(Pl_Pos[i2]);
                    end;
          end;
          case cm of
            1 : begin
                  if CData and $80 = 0 then access($b0+i2,0);
                   fre:= NotFreqs[(cdata) and $0f] or ((cdata and $f0) shl 6);
                   sl[i2].fr := fre;
                   if cdata and $4000 = 0 then
                     access($43+chnums[i2],((cdata and $3f00)shr 8) or (Ins[CurIns[i2],3] and $c0))
                   else access($43+chnums[i2],ins[curins[i2],3]);
                   access($a0+i2,fre and $ff);
                   access($b0+i2,(fre shr 8) and 31+32);
                   sl[i2].on := false;
                end;
            2 : begin
                  access($b0+i2,0);
                  sl[i2].on := false;
                end;
            4 : begin
                  CurIns[i2] := cdata;
                  setsound(i2);
                end;
            5 : Tempo := cdata;
            6 : begin
                  bdval := bdval or 32;
                  access($bd,bdval);
                end;
            7 : begin
                  bdval := bdval and $ef;
                  access($bd,bdval);
                end;
            9 : access($40+chnums[i2],(cdata and $3f) or (Ins[CurIns[i2],2] and $c0));
            10: access($43+chnums[i2],(cdata and $3f) or (Ins[CurIns[i2],3] and $c0));
            11: begin
                  slide := cdata;
                  sl[i2].dir := 1;
                end;
            12: begin
                  slide := cdata;
                  sl[i2].dir := 2;
                end;
            16: begin
                  if cdata <= 16 then dela := round((cdata / 16) * Tempo)
                  else dela := 0;
                  dl[i2].on := true;
                  dl[i2].val:= dela;
                 { dl[i2].nt := cnote; }
                end;
           $ff: begin
                  ResetSong;
                  goto 2;
                end;
          end;
          Pl_Wait[i2] := mem[seg(channel[i2]^):Pl_Pos[i2]];
          inc(Pl_Pos[i2]);
          if Pl_Wait[i2] = 0 then goto 1;
         end;
        end
        else dec(Pl_Wait[i2]);
        Pl_Count := tempo;
      end;
    end
    else dec(Pl_Count);
  end;
2:
end;

end.