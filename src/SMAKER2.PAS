program testsound;

uses Crt,dos;

type
    SoundData = array[0..15] of Byte;

var
   sound :SoundData;
   p     : byte;
   sstate,gog : Boolean;
   key   : Char;
   sp    : Byte;
   b,q,c,a : byte;
   in1,in3 : word;
   waveon  : boolean;

const
     curoct = 3;
     BnkFile : string[12] = 'sound.bnk';
     BnkPath = '';
     NotFreqs : array[1..12] of word = ($156,$16b,$181,$198,$1b0,$1ca,
                                        $1e5,$202,$220,$241,$263,$287);

procedure access(reg,value:byte); Assembler;
          asm
             mov dx,220h
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
          end; {access}

procedure init;
          var
             a:integer;
          begin
               a := 0;
               repeat
                     inc(a);
                     access(a,0);
               until a = $f5;
          end;

procedure soundon(ch:Byte;fr:word);
          begin
               access($20+ch,sound[0]);
               access($23+ch,sound[1]);
               access($40+ch,sound[2]);
               access($43+ch,sound[3]);
               access($60+ch,sound[4]);
               access($63+ch,sound[5]);
               access($80+ch,sound[6]);
               access($83+ch,sound[7]);
               access($e0+ch,sound[8]);
               access($e3+ch,sound[9]);
               access($c0+ch,sound[10]);
               access($a0+ch,fr and $ff);
               access($b0+ch,fr shr 8 and 31+32);

          end;{soundon}

procedure soundoff(ch:byte);
          begin
               access($a0+ch,$00);
               access($b0+ch,$00);
          end;{soundoff}

procedure loadsound(n:integer);
          var a:integer;

              f:text;
              c:char;
          begin
               n := n*16;
               Assign(f,BnkPath+BnkFile);
               Reset(f);
               for a:=1 to n do read(f,c);

               for a:=0 to 15 do
               begin
                    read(f,c);
                    sound[a]:=ord(c);
               end;
               close(f);
          end;{loadsound}

procedure Savesound;
          var a:byte;

              f:text;
              c:char;
          begin
               Assign(f,BnkPath+BnkFile);
               Append(f);
               for a:=0 to 15 do write(f,chr(sound[a]));
               close(f);

          end;{savesound}

procedure check(n:byte);
           begin
                if n = p then
                begin
                     textcolor(0);
                     textbackground(7);
                end
                else
                begin
                     textcolor(7);
                     textbackground(0);
                end;
           end;{check}

procedure active(n:byte);
          procedure ask(x,y : integer);
                   var s: string[2];
                       f,o: integer;
                   begin
                        if y = 0 then
                        begin
                             inc(sound[x]);
                             if sound[x] and 15 = 0 then sound[x] := sound[x] -16;
                        end
                        else sound[x] := sound[x] + 16;

                   end;

          var sn : integer;
              st : string[2];
              fuck:integer;
          begin
               case n of
                    0     : sound[0] := sound[0] xor $80;
                    1     : sound[1] := sound[1] xor $80;
                    2     : sound[0] := sound[0] xor $40;
                    3     : sound[1] := sound[1] xor $40;
                    4     : sound[0] := sound[0] xor $20;
                    5     : sound[1] := sound[1] xor $20;
                    6     : sound[0] := sound[0] xor $10;
                    7     : sound[1] := sound[1] xor $10;
                    8     : ask(0,0);
                    9     : ask(1,0);
                    10    : sound[2] := sound[2] + $40;
                    11    : sound[3] := sound[3] + $40;
                    12    : sound[2] := sound[2] + 1;
                    13    : sound[3] := sound[3] + 1;
                    14    : ask(4,1);
                    15    : ask(5,1);
                    16    : ask(4,0);
                    17    : ask(5,0);
                    18    : ask(6,1);
                    19    : ask(7,1);
                    20    : ask(6,0);
                    21    : ask(7,0);
                    22    : ask(8,0);
                    23    : ask(9,0);
                    24    : ask(10,0);
                    25    : sound[10] := sound[10] xor 1;
                    26    : savesound;
                    27    : begin
                                 textcolor(15);
                                 GotoXY(1,wherey);
                                 Write('Sound Number: ');
                                 Read(sn);
                                 loadsound(sn);
                                 textcolor(7);
                            end;
                    28    : begin
                                 GotoXY(1,wherey);
                                 textcolor(15);
                                 write('Sure?');
                                 key := readkey;
                                 if Key = 'y' then
                                 begin
                                      clrscr;
                                      Writeln('Thank You!');
                                      init;
                                      halt(1);
                                 end
                            end;
               end;
          end;{active}

procedure clear;
          begin
               for b := 0 to 15 do sound[b] := 0;
          end;

procedure oper(n:integer);
          begin
               check(c);
               GotoXY(38,wherey);
               q := sound[b] and n;
               write(q);
               check(255);
               write('  ');
               if not gog then
               begin
               inc(c);
               inc(b);
               check(c);
               GotoXY(50,wherey);
               q := sound[b] and n;
               write(q);
               check(255);
               write('  ');
               dec(b);
               end;
               inc(c);
               GotoXY(1,Wherey+1);
          end;

begin
     if paramStr(1) <> '' then BnkFile := ParamStr(1);
     p := 0;
     access($bd,$c0);
     clear;
     init;
     sstate := false;
     gog    := false;
           Clrscr;
           textbackground(1);
           Writeln('Sound Maker v 1.1  (c) Don Unonen           Sound is               ',BnkFile);
           check(255);
           writeln;

           textcolor(4);
           Writeln('Register Explanation                 Modulator  Carrier');
           textcolor(1);
           Writeln('Amplitude Modulation');
           Writeln('Vibrato');
           Writeln('Envelope Generator Type');
           Writeln('Keyboard Scaling Rate');
           Writeln('Modulator Frequency Multiple (0-15)');
           Writeln('Scaling (0-15)');
           Writeln('Output (0-15)');
           Writeln('Attack (0-15)');
           Writeln('Decay (0-15)');
           Writeln('Sustain (0-15)');
           Writeln('Release (0-15)');
           Writeln('Wawe select (0-3)');
           Writeln('Feedback (0-8)');
           Writeln('Algorithm');
           repeat
                 b := 0;
                 c := 0;
                 GotoXY(54,1);
                 textcolor(4);
                 if sstate then write('ON ')
                 else write('OFF');
                 GotoXY(1,4);
                 GotoXY(40,wherey);
                       oper($80);
                       oper($40);
                       oper($20);
                       oper($10);
                       oper($0f);
                       check(c);
                       b:= b+2;
                       oper($c0);
                       oper($3f);
                       check(c);
                       b:= b+2;

                       repeat
                             oper($f0);
                             oper($0f);
                             b:=b+2;
                       until b = 8;
                       oper($03);
                       b:= b+2;
                       gog := true;
                       oper(14);
                       oper(1);
                       gog := false;
           GotoXY(1,18);
           check(c);
           Writeln('Save Sound');
           inc(c);
           check(c);
           Writeln('Load Sound');
           inc(c);
           check(c);
           Writeln('Quit');
           check(255);
       in1 := 0;
       in3 := 1;
           for a:= 0 to 15 do write(chr(sound[a]));
           key := readkey;
           case key of
                ' '    : sstate := not sstate;
               #72     : begin
                           if p < 25 then p:= p-2
                           else dec(p);
                      end;
               #80     : begin
                           if p < 23 then p:= p+2
                           else inc(p);
                      end;
               #75     : dec(p);
               #77     : inc(p);
               #13     : begin
                              gotoXY(1,21);
                              writeln('                         ');
                              active(p);
                         end;
               ''     : waveon := not waveon;
           end;
       in1 := 0;
       in3 := 1;
       case key of
            'z'     : in1 := 1 or (CurOct shl 4);
            's'     : in1 := 2 or (CurOct shl 4);
            'x'     : in1 := 3 or (CurOct shl 4);
            'd'     : in1 := 4 or (CurOct shl 4);
            'c'     : in1 := 5 or (CurOct shl 4);
            'v'     : in1 := 6 or (CurOct shl 4);
            'g'     : in1 := 7 or (CurOct shl 4);
            'b'     : in1 := 8 or (CurOct shl 4);
            'h'     : in1 := 9 or (CurOct shl 4);
            'n'     : in1 := 10 or (CurOct shl 4);
            'j'     : in1 := 11 or (CurOct shl 4);
            'm'     : in1 := 12 or (CurOct shl 4);
            #44     : in1 := 1 or (CurOct +1) shl 4;
            'l'     : in1 := 2 or (CurOct +1 ) shl 4;
            #46     : in1 := 3 or (CurOct +1 ) shl 4;
            '”'     : in1 := 4 or (CurOct +1 ) shl 4;
            '-'     : in1 := 5 or (CurOct +1 ) shl 4;

            'q'     : in1 := 1 or (CurOct +1 ) shl 4;
            '2'     : in1 := 2 or (CurOct +1 ) shl 4;
            'w'     : in1 := 3 or (CurOct +1 ) shl 4;
            '3'     : in1 := 4 or (CurOct +1 ) shl 4;
            'e'     : in1 := 5 or (CurOct +1 ) shl 4;
            'r'     : in1 := 6 or (CurOct +1 ) shl 4;
            '5'     : in1 := 7 or (CurOct +1 ) shl 4;
            't'     : in1 := 8 or (CurOct +1 ) shl 4;
            '6'     : in1 := 9 or (CurOct +1 ) shl 4;
            'y'     : in1 := 10 or (CurOct +1 ) shl 4;
            '7'     : in1 := 11 or (CurOct +1 ) shl 4;
            'u'     : in1 := 12 or (CurOct +1 ) shl 4;
            'i'     : in1 := 1 or (CurOct +2 ) shl 4;
            '9'     : in1 := 2 or (CurOct +2 ) shl 4;
            'o'     : in1 := 3 or (CurOct +2 ) shl 4;
            '0'     : in1 := 4 or (CurOct +2 ) shl 4;
            'p'     : in1 := 5 or (CurOct +2 ) shl 4;

            'Z'     : in1 := 1 or (CurOct-1 ) shl 4;
            'S'     : in1 := 2 or (CurOct-1 ) shl 4;
            'X'     : in1 := 3 or (CurOct-1 ) shl 4;
            'D'     : in1 := 4 or (CurOct-1 ) shl 4;
            'C'     : in1 := 5 or (CurOct-1 ) shl 4;
            'V'     : in1 := 6 or (CurOct-1 ) shl 4;
            'G'     : in1 := 7 or (CurOct-1 ) shl 4;
            'B'     : in1 := 8 or (CurOct-1 ) shl 4;
            'H'     : in1 := 9 or (CurOct-1 ) shl 4;
            'N'     : in1 := 10 or (CurOct-1 ) shl 4;
            'J'     : in1 := 11 or (CurOct-1 ) shl 4;
            'M'     : in1 := 12 or (CurOct-1 ) shl 4;
            #59     : in1 := 1 or (CurOct shl 4);
            'L'     : in1 := 2 or (CurOct shl 4);
            #58     : in1 := 3 or (CurOct shl 4);
            '™'     : in1 := 4 or (CurOct shl 4);
            '_'     : in1 := 5 or (CurOct shl 4);

            'Q'     : in1 := 1 or (CurOct +2 ) shl 4;
            '"'     : in1 := 2 or (CurOct +2 ) shl 4;
            'W'     : in1 := 3 or (CurOct +2 ) shl 4;
            '#'     : in1 := 4 or (CurOct +2 ) shl 4;
            'E'     : in1 := 5 or (CurOct +2 ) shl 4;
            'R'     : in1 := 6 or (CurOct +2 ) shl 4;
            '%'     : in1 := 7 or (CurOct +2 ) shl 4;
            'T'     : in1 := 8 or (CurOct +2 ) shl 4;
            '&'     : in1 := 9 or (CurOct +2 ) shl 4;
            'Y'     : in1 := 10 or (CurOct +2 ) shl 4;
            '/'     : in1 := 11 or (CurOct +2 ) shl 4;
            'U'     : in1 := 12 or (CurOct +2 ) shl 4;
            'I'     : in1 := 1 or (CurOct +3 ) shl 4;
            ')'     : in1 := 2 or (CurOct +3 ) shl 4;
            'O'     : in1 := 3 or (CurOct +3 ) shl 4;
            '='     : in1 := 4 or (CurOct +3 ) shl 4;
            'P'     : in1 := 5 or (CurOct+3 ) shl 4;

       end;
           if p >29 then p := 28;
           if p =29 then p := 0;
           if in1 <> 0 then
           begin
                soundoff(0);
                delay(1);
                soundon(0,NotFreqs[in1 and $0f] or (in1 and $70) shl 6);
           end
           else
           begin
                soundoff(0);
           end;
           if waveon then access(1,1)
           else access(1,0);
     until false;
end.