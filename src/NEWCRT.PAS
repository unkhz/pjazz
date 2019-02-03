unit NewCrt;
{$v-} {$p-}
Interface
uses dos;

type
    virtextptr = ^virtexttype;
    virtexttype = array[1..8000] of byte;
    PosREC = record
                   x,y :byte;
             end;
var
    virtext :virtextptr;        { ptr to Virtual Text Screen }
    taddr   :word;              { address of   '' }
    tcol    :byte;              { current color }
    Tpos    :PosREC;              { current position }

const
     tseg = $b800;
function getkey:word;
  { returns with keys scancode }
function i2s(n:word):string;
  { integer to string }
function s2i(s:string):word;
  { string to integer }
function b2s(n:word):string;
procedure WVR;
  { waits for vertical retrace }
procedure WHR;
  { waits for horizontal retrace }
procedure SetVT;
  { sets up Virtual Text screen }
procedure RemVT;
  { removes Virtual Text Screen }
procedure WrXY(str1:string;x,y:byte);
  { writes a string to VT to x,y }
procedure RdXY(var str1:string;x,y,l,c:byte);
procedure Rdstr(var str1:string;x,y,l,c:byte);
  { reads a string }
procedure RdInt(var toi:byte;x,y,l,c:byte);
  { reads an integer value }
procedure WrCol(str1:string;x,y,col:byte);
  { writes a string with color }
procedure cursoroff;
  { disables cursor }
procedure cursoron;
  { enables cursor }
procedure PrWin(x1,y1,x2,y2: byte; Col,cha: Byte );
  { draws a window to VT }
procedure PrColWin(x1,y1,x2,y2: byte; Col: Byte );
  { draws a window to VT }
procedure PrFColWin(x1,y1,x2,y2:byte; col:byte);
procedure ClrVT;
  { Clears the VT }
procedure PrVT;
  { Prints The VT to screen }
procedure WrStr(st1:string);
  { writes a string to VT to TPos }
procedure SetTRate(r,d:byte);
  { sets typematic rate and delay }
Procedure Pal(Col,R,G,B : Byte);

procedure BordWin(x1,y1,x2,y2,col,bcol:byte);
Procedure GetPal(Col : Byte; Var R,G,B : Byte);

Implementation

function getkey:word;
var regs:registers;
begin
    regs.ah := 0;
    intr($16,regs);
    getkey := regs.ax;
end;

function i2s(n:word):string;
var st1:string;
begin
     str(n,st1);
     i2s := st1;
end;
function b2s(n:word):string;
var st1:string;
begin
     str(n,st1);
     if n < 10 then st1 := '0'+ st1;
     b2s := st1;
end;

function s2i(s:string):word;
var i,code:integer;
begin
     val(s,i,code);
     if code <> 0 then i := 0;
     s2i := i;
end;

procedure WVR; assembler;
asm
    mov dx,3DAh
@l1:
    in al,dx
    and al,08h
    jnz @l1
@l2:
    in al,dx
    and al,08h
    jz  @l2
end;

procedure WHR; assembler;
asm
  mov dl,0dah        { horizontal retrace }
 @hor1:
  in al,dx
  test al,1
  jnz @hor1
 @hor2:
  in al,dx
  test al,1
  jz @hor2
end;

procedure SetVT;
begin
     GetMem(VirText,8000);
     taddr := seg (VirText^);
     TCol := 0;
     TPos.x := 0;
     TPos.y := 0;
end;

procedure RemVT;
begin
     FreeMem(VirText,8000);
     taddr := 0;
end;

procedure WrXY(str1:string;x,y:byte);
var ind1:byte;
begin
     for ind1 := 0 to length(str1)-1 do
     begin
          mem[taddr:(y*80+x+ind1) shl 1] := ord(str1[ind1+1]);
     end;
end;

procedure RdXY(var str1:string;x,y,l,c:byte);
var s1:string;
    i1:byte;
    k :word;
    k1:byte;
    HPos : PosREC;
begin
     s1 := '';
     i1 := 0;
     Hpos.x :=x;
     HPos.y :=y;
     repeat
       PrWin(x,y,x+l,y,c,32);
       if length(s1) <> 0 then WrXY(s1,x,y);
       PrVT;
       mem[tseg:(HPos.y*80+HPos.x)shl 1 +1] := (c shl 4) + (c shr 4);
       k := GetKey;
       k1:= k and $ff;
       if k1 in [33..122] then
       begin
         inc(i1);
         s1 := s1 + chr(k1);
         inc(HPos.X);
       end
       else
       if (k = $0e08) and (i1 > 0) then
       begin
         dec(i1);
         dec(HPos.x);
         s1 := copy(s1,1,length(s1)-1);
       end;
     until (i1 = l) or (k1 in [$0d,$1b]);
     if (k = $011b) or (i1 = 0) then s1 := ' ';
     str1 := s1;
end;

procedure RdStr(var str1:string;x,y,l,c:byte);
var s1:string;
    i1:byte;
    k :word;
    k1:byte;
    HPos : PosREC;
begin
     s1 := '';
     i1 := 0;
     Hpos.x :=x;
     HPos.y :=y;
     repeat
       PrWin(x,y,x+l,y,c,32);
       if length(s1) <> 0 then WrXY(s1,x,y);
       PrVT;
       mem[tseg:(HPos.y*80+HPos.x)shl 1 +1] := (c shl 4) + (c shr 4);
       k := GetKey;
       k1:= k and $ff;
       if k1 in [32..254] then
       begin
         inc(i1);
         s1 := s1 + chr(k1);
         inc(HPos.X);
       end
       else
       if (k = $0e08) and (i1 > 0) then
       begin
         dec(i1);
         dec(HPos.x);
         s1 := copy(s1,1,length(s1)-1);
       end;
     until (i1 = l) or (k1 in [$0d,$1b]);
     if (k = $011b) or (i1 = 0) then s1 := ' ';
     str1 := s1;
end;

procedure RdInt(var toi:byte;x,y,l,c:byte);
var s1:string;
    i1:byte;
    k :word;
    k1:byte;
    HPos:PosREc;
begin
     s1 := '';
     i1 := 0;
     HPos.X := x;
     HPos.y := y;
     repeat
       PrWin(x,y,x+l-1,y,c,32);
       if length(s1) <> 0 then WrXY(s1,x,y);
       PrVT;
       mem[tseg:(HPos.y*80+HPos.x)shl 1 +1] := (c shl 4) + (c shr 4);
       k := GetKey;
       k1:= k and $ff;
       if k1 in [48..57] then
       begin
         inc(i1);
         s1 := s1 + chr(k1);
         inc(HPos.X);
       end
       else
       if (k = $0e08) and (i1 > 0) then
       begin
         dec(i1);
         dec(HPos.x);
         s1 := copy(s1,1,length(s1)-1);
       end;

     until (i1 = l) or (k1 in [$0d,$1b]);
       for i1 := 0 to 255 do ;
     if k <> $011b then toi := s2i(s1);
end;

procedure WrCol(str1:string;x,y,col:byte);
var ind1:byte;
begin
     for ind1 := 0 to length(str1)-1 do
     begin
          mem[taddr:(y*80+x+ind1) shl 1+1] := col;
          mem[taddr:(y*80+x+ind1) shl 1] := ord(str1[ind1+1]);
     end;
end;

procedure cursoroff; assembler;
asm
  mov ah,3
  mov bh,0
  int 10h
  or ch,20h
  mov ah,1
  int 10h
end;

procedure cursoron; assembler;
asm
  mov ah,3
  mov bh,0
  int 10h
  and ch,not 20h
  mov ah,1
  int 10h
end;

procedure PrWin(x1,y1,x2,y2: byte; Col,cha: Byte ); Assembler;
Asm
     cld
     mov   es,taddr     { set ES to text-mem start }
     mov   DL,80        { Set DI to x+y * 80 }
     sub   AH,AH
     mov   AL,y1
     mul   DL
     add   AL,x1
     shl   AX,1
     mov   DI,AX

     sub   BH,BH
     mov   BL,79
     sub   BL,x2
     add   BL,x1
     shl   BL,1

     mov   AL,Cha       { Set AX to value }
     mov   AH,Col
     mov   DH,y2        { Set DH to y count }
     sub   DH,y1
     inc   DH
     sub   CX,CX
     mov   DL,x2        { reset x count }
     sub   DL,x1
     inc   DL
     mov   CL,DL
@LOOP:
     rep   stosW        { Draw line }
     add   CL,DL        { reset x count }
     add   DI,BX        { Add inc count }
     dec   DH           { Dec y count }
     jg  @LOOP
end;

procedure PrColWin(x1,y1,x2,y2:byte; col:byte);
var i1,i2:byte;
begin
     for i1 := x1 to x2 do
       for i2 := y1 to y2 do
         mem[taddr:((i2*80 + i1) shl 1)+1] := col;
end;

procedure PrFColWin(x1,y1,x2,y2:byte; col:byte);
var i1,i2:byte;
begin
     for i1 := x1 to x2 do
       for i2 := y1 to y2 do
         mem[taddr:((i2*80 + i1) shl 1)+1] := (mem[taddr:((i2*80 + i1) shl 1)+1] and $f0) or col;
end;

procedure ClrVT; Assembler;
Asm
     cld
     mov   DX,Taddr
     mov   ES,DX
     sub   DI,DI    { set ES to text-mem start }
     mov   AL,32       { Set AX to value }
     mov   AH,TCol
     mov   CX,4000      { reset x count }
     rep   stosW        { Draw line }
end;

procedure PrVT;
var i1 : word;
begin
     WVR;
     for i1 := 0 to 7999 do
       mem[tseg:i1] := mem[taddr:i1];
end;

procedure WrStr(st1:string);
var i1:word;
begin
     for i1 := 0 to length(st1)-1 do
       mem[taddr:(TPos.y*80+tpos.x+i1) shl 1] := ord(st1[i1+1]);
     inc(TPos.x,length(st1));
     if TPos.x > 80 then
     begin
          TPos.x := 0;
          TPos.y := TPos.y+1;
     end;
end;

procedure SetTRate(r,d:byte); assembler;
asm
   mov  AH,03h
   mov  AL,05h
   mov  BH,d
   mov  BL,r
   int  16
end;

procedure BordWin(x1,y1,x2,y2,col,bcol:byte);
var i1 : byte;
begin
     PrWin(x1-1,y1-1,x2+1,y2+1,bcol,32);
     wrXY('É',x1-1,y1-1);
     for i1 := 0 to x2-x1 do wrXY('Í',x1+i1,y1-1);
     wrxy('»',x2+1,y1-1);
     for i1 := 0 to y2-y1 do
     begin
          wrxy('º',x1-1,y1+i1);
          wrxy('º',x2+1,y1+i1);
     end;
     wrxy('È',x1-1,y2+1);
     for i1 := 0 to x2-x1 do wrxy('Í',x1+i1,y2+1);
     wrxy('¼',x2+1,y2+1);
     {PrWin(x1,y1,x2,y2,col,32);}
end;

Procedure Pal(Col,R,G,B : Byte);assembler;
  { This sets the Red, Green and Blue values of a certain color }
   asm
      mov    dx,3c8h
      mov    al,[col]
      out    dx,al
      inc    dx
      mov    al,[r]
      out    dx,al
      mov    al,[g]
      out    dx,al
      mov    al,[b]
      out    dx,al
   end;
Procedure GetPal(Col : Byte; Var R,G,B : Byte);
  { This gets the Red, Green and Blue values of a certain color }
Var
   rr,gg,bb : Byte;
Begin
   asm
      mov    dx,3c7h
      mov    al,col
      out    dx,al

      add    dx,2

      in     al,dx
      mov    [rr],al
      in     al,dx
      mov    [gg],al
      in     al,dx
      mov    [bb],al
   end;
   r := rr;
   g := gg;
   b := bb;
end;

end.