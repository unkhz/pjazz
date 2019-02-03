program UMFPlayTest;
uses UMFPlay,crt,dos;
var in1,in2 :word;
begin
     InitSound;
     LoadUMF(paramstr(1)+'.UMF');
     if ErrCode = 0 then
     begin
       Writeln(' ** UMF PLAYER v1.0   (C) Don Unonen of Parallel Nightmares **');
       Writeln;
       Writeln('Playing '+title);
       Writeln('Press any key to stop');
       Playon := true;
       repeat until keypressed;
     end
     else writeln('Didn''t work. Sorry');
     DoneSound;
end.