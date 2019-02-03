program Playtest;

uses soundz3,Dos,crt,newcrt;

var
   Int1cSave : pointer;
   gop       : string;
   sound     : array[0..15] of byte;
   PlayCount : word;
   notenum    : byte;
   in1        :word;

const
     Tests : array[1..64] of byte = ($41,$40,$43,$40,$45,$40,$41,$40,$41,$40,
                                     $43,$40,$45,$40,$41,$40,$45,$40,$46,$40,
                                     $48,$40,$40,$40,$45,$40,$46,$40,$48,$40,
                                     $40,$40,$48,$4a,$48,$46,$45,$40,$41,$40,
                                     $48,$4a,$48,$46,$45,$40,$41,$40,$41,$40,
                                     $38,$40,$41,$40,$40,$40,$41,$40,$38,$40,
                                     $41,$40,$40,$40);

procedure PlayHandler; Interrupt;
var fre,fre2,i1,i2 : word;
begin

     begin
       if playcount = 0 then
       begin
         i1 := tests[notenum];
         if i1 and $0f <> 0 then
         begin
         for i2 := 0 to 3 do
         begin
         delay(80);
         access($a0,0,lport);
         access($b0,0,lport);
         fre:= NotFreqs[(i1) and $0f] or ((i1 and $f0) shl 6);
         access($a0,fre and $ff,lport);
         access($b0,(fre shr 8) and 31+32,lport);

         end;
         end;
         playcount := 3;
         if notenum < 64 then inc(notenum)
         else notenum := 1
       end
       else dec(playcount);
     end;
       Port[$20] := $20;
end;

procedure loadsound(n:integer);
          var a:integer;

              f:text;
              c:char;
          begin
               n := n*16;
               Assign(f,'sound.bnk');
               Reset(f);
               for a:=1 to n do read(f,c);

               for a:=0 to 15 do
               begin
                    read(f,c);
                    sound[a]:=ord(c);
               end;
               close(f);
          end;{loadsound}


begin
    asm
	   cli
	   mov	al,00110110b  ;
			      ;
			      ;
	   out	43h,al	      ;

	   mov	cx,8000h      ;
			      ;
	   mov	al,cl	      ;
	   out	40h,al
	   mov	al,ch	      ;
	   out	40h,al
	   sti
     end;
     pal(6,30,40,50);
     pal(8,20,60,50);
     textcolor(6);
     write('playing');
     textcolor(8);
     write('Jaakko Kulta...');
     loadsound(32);
     access($20+in1,sound[0],lport);
     access($23+in1,sound[1],lport);
     access($40+in1,sound[2],lport);
     access($43+in1,sound[3],lport);
     access($60+in1,sound[4],lport);
     access($63+in1,sound[5],lport);
     access($80+in1,sound[6],lport);
     access($83+in1,sound[7],lport);
     access($e0+in1,sound[8],lport);
     access($e3+in1,sound[9],lport);
     access($c0+in1,sound[10],lport);
     notenum := 0;
     GetIntVec($1c,Int1cSave);
     SetIntVec($1c,addr(PlayHandler));
     repeat readln(gop); until gop ='';
     soundinit;
     setintvec($1c,int1csave);
end.