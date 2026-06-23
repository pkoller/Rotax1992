


program Proj1992;                          { Ab 29.JÑnner 1992       }
uses
  crt,Graph,maus,help_g1;
type kanten = array [1..10,1..30] of integer;
const cursormaske : gctype = (
                              u0 : 8;
                              v0 : 8;
                          Bitmap :
 ($0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,
  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,
  $8000,$e000,$f800,$fe00,$d800,$0c00,$0600,$0300,
  $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000));

const cursormuster : Mustertype =
           ('1111100000011111',     { Im Bereich 0 Åberdeckt der}
            '1111000110001111',     { Mauscursor die Zeichnung  }
            '1110001111000111',
            '1100011111100011',
            '1000111111110001',
            '0001111111111000',
            '0001111111111000',
            '0001111111111000',
            '0001111111111000',
            '0001111111111000',
            '0011111111111101',
            '1001111111111001',
            '1000111111110001',
            '1100011111100011',
            '1110000110000111',
            '1111100000011111',

            '0000011111100000',
            '0001111001111000',
            '0011100000011100',
            '0111000000001110',
            '0110000000000110',
            '1100000000000011',
            '1100000110000011',
            '1100001001000011',
            '1100001001000011',
            '1100000110000011',
            '1100000000000011',
            '0110000000000110',
            '0111000000001110',
            '0011100000011100',
            '0001111001111000',
            '0000011111100000',
            '7',
            '7');


const
  Genau:byte=10;
  lin : array[1..54] of record              { nachziehbare Linien rechts }
                        x1 : integer;
                        y1 : integer;
                        x2 : integer;
                        y2 : integer;
                        k  : boolean;       { ist true fÅr sichtbare Kanten }
                        d  : boolean;       { wird true fÅr nachgezogene K. }
                        u  : boolean;       { ist true fÅr Urkîrper-Kanten  }
                        end=
   ((x1: 410; y1: 361; x2:510; y2:361),
    (x1: 510; y1: 361; x2:610; y2:361),
    (x1: 610; y1: 361; x2:585; y2:336),
    (x1: 585; y1: 336; x2:560; y2:311),
    (x1: 560; y1: 311; x2:460; y2:311),
    (x1: 460; y1: 311; x2:360; y2:311),
    (x1: 360; y1: 311; x2:385; y2:336),
    (x1: 385; y1: 336; x2:410; y2:361),
    (x1: 385; y1: 336; x2:485; y2:336),
    (x1: 485; y1: 336; x2:585; y2:336),
    (x1: 510; y1: 361; x2:485; y2:336),
    (x1: 485; y1: 336; x2:460; y2:311),
    (x1: 410; y1: 261; x2:510; y2:261),
    (x1: 510; y1: 261; x2:610; y2:261),
    (x1: 610; y1: 261; x2:585; y2:236),
    (x1: 585; y1: 236; x2:560; y2:211),
    (x1: 460; y1: 211; x2:560; y2:211),
    (x1: 460; y1: 211; x2:360; y2:211),
    (x1: 360; y1: 211; x2:385; y2:236),
    (x1: 385; y1: 236; x2:410; y2:261),
    (x1: 385; y1: 236; x2:485; y2:236),
    (x1: 485; y1: 236; x2:585; y2:236),
    (x1: 510; y1: 261; x2:485; y2:236),
    (x1: 485; y1: 236; x2:460; y2:211),
    (x1: 410; y1: 161; x2:510; y2:161),
    (x1: 510; y1: 161; x2:610; y2:161),
    (x1: 610; y1: 161; x2:585; y2:136),
    (x1: 585; y1: 136; x2:560; y2:111),
    (x1: 560; y1: 111; x2:460; y2:111),
    (x1: 460; y1: 111; x2:360; y2:111),
    (x1: 360; y1: 111; x2:385; y2:136),
    (x1: 385; y1: 136; x2:410; y2:161),
    (x1: 385; y1: 136; x2:485; y2:136),
    (x1: 485; y1: 136; x2:585; y2:136),
    (x1: 510; y1: 161; x2:485; y2:136),
    (x1: 485; y1: 136; x2:460; y2:111),
    (x1: 410; y1: 361; x2:410; y2:261),
    (x1: 510; y1: 361; x2:510; y2:261),
    (x1: 610; y1: 361; x2:610; y2:261),
    (x1: 585; y1: 336; x2:585; y2:236),
    (x1: 560; y1: 311; x2:560; y2:211),
    (x1: 460; y1: 311; x2:460; y2:211),
    (x1: 360; y1: 311; x2:360; y2:211),
    (x1: 385; y1: 336; x2:385; y2:236),
    (x1: 485; y1: 336; x2:485; y2:236),
    (x1: 410; y1: 261; x2:410; y2:161),
    (x1: 510; y1: 261; x2:510; y2:161),
    (x1: 610; y1: 261; x2:610; y2:161),
    (x1: 585; y1: 236; x2:585; y2:136),
    (x1: 560; y1: 211; x2:560; y2:111),
    (x1: 460; y1: 211; x2:460; y2:111),
    (x1: 360; y1: 211; x2:360; y2:111),
    (x1: 385; y1: 236; x2:385; y2:136),
    (x1: 485; y1: 236; x2:485; y2:136));
var
  Gd, Gm,t,xcor,ycor,tausch,j,Nr: Integer;
  x,y,i,wer : word;
  distanz,werte : string;
  Abst,Wurzel :real;
  normx,normy,wert :longint;
  fertig :boolean;
  fest :Kanten;
  Kt : file of Kanten;

{$I Grafini.inc}
{$I Titel.inc}


procedure lesen;
begin
randomize;
  repeat
   Nr:=random(5)+1;
  until Nr mod 2 <> 0;
{$I-}
     assign(Kt,'d:\tp6\prog\Koe.dat');
  reset(Kt);
     {$I+}
     if IOResult <> 0 then
         begin
          cleardevice;
          write('Ich kann die Datei Koe.dat nicht finden');
         end;
      read(Kt,fest);
      for i:= 1 to 27 do
         begin
          j:=fest[Nr,i];
           if j<> 0 then
          lin[j].k:=true;

          j:=fest[Nr+1,i];
           if j<> 0 then
          lin[j].u:=true;
         end;
         if fest[Nr,28]<>0 then
          begin
           lin[fest[Nr,28]].x2:=fest[Nr,29];
           lin[fest[Nr,28]].y2:=fest[Nr,30];
          end;

end;

Procedure Achsen;
begin
  setlinestyle(4,255,2);                   { selbstdef. Linie (S. 415}
  line(getmaxx div 2,20,getmaxx div 2,getmaxy-20); { Drehachse       }
  moveto(360,111);
  setlinestyle(0,0,1); setcolor(cyan);
  lineto(319,70);
  ellipse(319,70,180,297,36,18);
  lineto (210,70);
  setfillstyle(0,0); floodfill(319,75,cyan);
end;


Procedure Urkoerper;
begin
   if fest[Nr+1,28]<>0 then
          begin



           lin[fest[Nr+1,28]].x2:=fest[Nr+1,29];



           lin[fest[Nr+1,28]].y2:=fest[Nr+1,30];
          end;
  setcolor(green);
  setlinestyle(0,0,3);                     { Linie durchgezogen, dick}
   for i:=1 to 54 do
     begin
     with lin[i] do
     if u=true then
     line(x1-350,y1-41,x2-350,y2-41)
     end;
  end;

  procedure Duennkoerper;
  begin
   setlinestyle(0,0,1);
   setcolor(6);                             { Zeichenfarbe braun      }
   fertig := false;
   for i:=1 to 54 do
     begin
     with lin[i] do
     line(x1,y1,x2,y2)
     end;
  end;

procedure fuellen;
begin
mauscursor(false);
setcolor(black);
for i:=1 to 54 do       { lîscht dir ÅberflÅssigen Linien }
   begin
      with lin[i] do
    begin
     if k=false then
     line(x1,y1,x2,y2)
    end
  end;
setcolor(green);
for i:=1 to 54 do
   begin                { zeichnet die sichtbaren Kanten nach }
   with lin[i] do
    begin
     if k=true then
     line(x1,y1,x2,y2)
    end
  end;
setfillstyle(1,2);
floodfill(420,271,2);
floodfill(15,250,2);
setfillstyle(1,8);
floodfill(70,290,2);
floodfill(370,250,2);
end;


procedure wertung;
begin
inc(wer);
setviewport(60,410,160,460,false);
settextstyle(3,0,5);
str(wer,werte);
clearviewport;                         { Lîscht Wertungsfenster }
rectangle(0,0,98,48);
setcolor(yellow);
outtext(' '+werte);
setviewport(0,0,getmaxx,getmaxy,false);
end;



procedure nachziehen;
var f:byte;
begin
f:=0;wer:=0;
  repeat
     repeat until gedrueckt (1) or gedrueckt (2);
     if gedrueckt (2) then fertig := true;
     position(x,y);
     xcor :=x; ycor :=y;
       i:=1;
       while i<55 do begin
       with lin[i] do begin
       normx  := (y2-y1);
       normy  := (x1-x2);
       Wurzel:= sqrt(normx*normx+normy*normy);
       Wert := (((xcor) - x2) * normx) + (((ycor) - y2) * normy);
       Abst   := abs(Wert)/wurzel;
         if (ABST<genau) then
         if ((x2>=x1) and (y1>=y2) and (xcor>=x1-2) and (xcor<=x2+2) and (ycor<=y1) and (ycor>=y2))
         or ((x2>=x1) and (y2>=y1) and (xcor>=x1+2) and (xcor<=x2-2) and (ycor>=y1-2) and (ycor<=y2+2))
         or ((x1>=x2) and (y2>=y1) and (xcor>=x2+2) and (xcor<=x1-2) and (ycor>=y1-2) and (ycor<=y2+2))
         or ((x1>=x2) and (y1>=y2) and (xcor>=x2+2) and (xcor<=x1-2) and (ycor<=y1-2) and (ycor>=y2+2))
         then
         if (d=false) and (k=true) then
         begin setlinestyle(0,0,3);
          setcolor(green);
          mauscursor(false);       { Damit Cursor nicht die Linie Åberdeckt }
          line(x1,y1,x2,y2); inc(f); wertung;
          mauscursor(true); sound(1000); delay(100); nosound;
            if f=22 then fuellen;

          repeat until not gedrueckt(1); { Damit neulich Anklicken notwendig }
          d:=true;

        end;
        inc(i);
        end
        end;
  until fertig = true;
end;



begin
textbackground(1);clrscr;
grafini;
{titel;}
Achsen;
Duennkoerper;
lesen;
mauscursor(true);
Urkoerper;
nachziehen;
mauscursor(false);
CloseGraph;
end.

