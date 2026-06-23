unit maus;

interface

type GCType = record
                u0,v0  : word;                 { Zentrumskoordinaten }
                BitMap : array[0..31] of word  { Grafik-Cursormaske }
              end;

{ Zur Definition eines eigenen Grafikcursors:
  u0,v0 .. Zentrum der Maske wird definiert:
           (Dieser Punkt des Cursors liefert die Positionswerte)
  BitMap:
  Die ersten 2*16 bytes definieren die "AND"-Maske (VerknÅpfung der Schirmbits
                                           mit den Maskenbits durch AND),
  die zweiten 2*16 bytes def. die "XOR"-Maske;     (Ergebnis der AND-Verk.
                                           wird mit diesen Maskenbits durch
                                           ein XOR verknÅpft).
  zB.: const gc_maske : GCType = (
             u0 : 8;
             v0 : 8;
         BitMap : ($ffff,$ffff,$ffff,$ffff,$ffff,$ffff,$ffff,$ffff,
                   $ffff,$ffff,$ffff,$ffff,$ffff,$ffff,$ffff,$ffff,
                   $8000,$E000,$F800,$FE00,$D800,$0C00,$0600,$0300,
                   $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000) );

  Belegung eines entsprechenden Records ist Voraussetzung fÅr die
  Prozedur EigenerGrafikCursor !;
  Eine Erleichterung dazu bietet die Prozedur Trafo }

     MusterType = array[0..33] of string[16];

{ Um die Definition eines eigenen Grafikcursors zu erleichtern:
  zB.:const GC1Muster : MusterType  =
                 ('1111100000011111',  ø
                  '1111000110001111',  ≥
                  '1110001111000111',  ≥
                  '1100011111100011',  ≥
                  '1000111001110001',  ≥
                  '0001111001111000',  ≥
                  '0001111001111000',  ≥
                  '0001000000001000',  ≥   AND - Maske
                  '0001111001111000',  ≥
                  '0001111001111000',  ≥
                  '1000111001110001',  ≥
                  '1100011111100011',  ≥
                  '1110001111000111',  ≥
                  '1111000110001111',  ≥
                  '1111100000011111',  ≥
                  '1111110000111111',  Ÿ

                  '0000011111000000',  ø
                  '0000110001100000',  ≥
                  '0001100000110000',  ≥
                  '0011000000011000',  ≥
                  '0110000100001100',  ≥
                  '1100000100000110',  ≥
                  '1100000100000110',  ≥
                  '1100111111100110',  ≥   XOR - Maske
                  '1100000100000110',  ≥
                  '1100000100000110',  ≥
                  '0110000100001100',  ≥
                  '0011000000011000',  ≥
                  '0001100000110000',  ≥
                  '0000110001100000',  ≥
                  '0000011111000000',  ≥
                  '0000000000000000',  Ÿ
                  '7',                     u0
                  '7');                    v0

           var GC1: GCType;
           begin
             TRAFO(BitMuster,GC1Muster);   (Erzeugt aus dem Bit - Muster
                                            die entsprechende Maske!)
           end.

   Bedeutung der Masken:
             Screen  AND-Maske  ZwischenR  XOR-Maske  Resultat
               0        0           0         0          0
               1        0           0         0          0  Immer 0

               0        1           0         0          0
               1        1           1         0          1  UnverÑndert

               0        0           0         1          1
               1        0           0         1          1  Immer 1

               0        1           0         1          1
               1        1           1         1          0  Invertierung }

procedure Trafo(var t:MusterType; var c:GCType);

{ Siehe oben! }

function Vorhanden(var tasten : integer):boolean;

{ True wenn eine funktionsfÑhige Maus angeschlossen ist }

procedure MausCursor(ein:boolean);

{ ein .. true  : einschalten
      .. false : ausschalten }

procedure PositionUndStatus(var x,y : word; var t1,t2,t3 : boolean);

{ Die Position geht von 0 .. 639, 0 .. 199;
  sie wird im Textmodus modulo 8 angegeben, im Farbgrafikmodus mod 2;
  t1,t2,t3 .. Taste 1, 2 oder 3 gedrÅckt }

procedure Position(var x,y : word);

{ Die Position geht von 0 .. 639, 0 .. 199;
  sie wird im Textmodus modulo 8 angegeben, im Farbgrafikmodus mod 2 }

procedure CursorPositionSetzen(x,y : integer);

function TasteGedrueckt(Gedrueckt : boolean;
                         nummer : integer;
                     var letztes_x,letztes_y,anzahl : integer):boolean;

{ Gedrueckt .. true:  taste "nummer" wurde gedrÅckt
            .. false:                      Losgelassen }

function Gedrueckt(nummer:byte):boolean;

{ Wird "true", wenn die Taste "nummer" gedrÅckt wird }

function Losgelassen(nummer:byte):boolean;

{ Wird "true", wenn die Taste "nummer" Losgelassen wird }

procedure MausNur(a,b,c,d:word);

{ Definiert einen erlaubten Bereich fÅr den Cursor }

procedure MausNie(a,b,c,d:word);

{ Definiert einen fÅr den Cursor verbotenen Bereich;
  in diesem Bereich wird der Cursor gelîscht und kann erst mit
  MausCursor(true) wieder eingeschaltet werden      }

procedure Relativbewegung(var delta_x,delta_y : integer);

{ Man bekommt die relative Bewegung seit dem letzten Aufruf dieser
  Prozedur                                           }

procedure BewegungsEinheiten(x,y : integer);

{  1/100 inch = 1 mickey
   mickey : pixel         = 1 :  1,
   mickey : zeichenbreite = 1 :  8,      (1 : x)  mit 1<=x,y<=32767
   mickey : zeichenhîhe   = 1 : 16.      (1 : y)
   Diese VerhÑltnisse kînnen mit dieser Prozedur verÑndert werden!  }

procedure DoppelteGeschwindigkeit(v : integer);

{ v in mickey/s gibt an, bei welcher Geschwindigkeit der Maus
  sich der Cursor nur noch mit der HÑlfte seiner ursprÅnglichen
  Geschwindigkeit bewegen soll }

procedure EigenerGrafikCursor(gc_maske:GCType);

{ Es wird ein eigener Cursor definiert;
  siehe GCType! }


procedure EigenerTextCursor(hard : boolean; und,entweder : word);

{ hard .. true:  die Grî·e des vorhandenen Hardwarecursors kann
                 verÑndert werden:   von Zeile  "und"
                                     bis Zeile  "entweder";
                 Je nach Text- oder Grafikkarte stehen verschieden viele
                 Zeilen fÅr den Cursor zur VerfÅgung( mono:14, CGA:8, VGA:16);
       .. false: die "AND" - Maske und
                 die "XOR" - Maske, mit denen die 2 Bildschirmbytes verknÅpft
                 werden, werden neu definiert:
     15  14  13  12  11  10   9   8   7   6   5   4   3   2   1   0
      B  fh  fh  fh   I  fv  fv  fv   ------- ASCII - Code -------- }

implementation
uses dos;
var  reg      : registers;

procedure Trafo;
  const wert : array['0'..'1'] of word = (0,1);
  var i,j,w : word;
      fehler: integer;

      procedure abbruch;
      begin
        writeln(#7);
        halt
      end;

  begin
    for i:= 0 to 31 do begin
      w:= 0;
      for j:= 1 to 16 do
        w:= w shl 1 + wert[t[i][j]];
      c.BitMap[i]:= w
      end;
      val(t[32],c.u0,fehler);
      if fehler<>0
         then abbruch;
      val(t[33],c.v0,fehler);
      if fehler<>0
         then abbruch
  end;

function Vorhanden;
begin
     with reg do begin
          ax:= $3533;        { Interrupt-Vektor fÅr Interrupt $33 holen }
          msdos(reg);
          if (es=0) and (bx=0)
             then Vorhanden:= false
             else begin
                  ax:= 0;    { Maus-Funktion: 0 }
                  intr($33,reg);
                  tasten:= bx;
                  Vorhanden:= ax=$ffff
                  end
          end
end;

procedure MausCursor;

begin
     with reg do begin
          if ein
             then ax:= 1
             else ax:= 2;
          intr($33,reg)
          end
end;


procedure PositionUndStatus;

begin
     with reg do begin
          ax:= 3;
          intr($33,reg);
          t1:= (bx and 1) = 1;  { Taste 1 gedrÅckt? }
          t2:= (bx and 2) = 2;  { Taste 2 gedrÅckt? }
          t3:= (bx and 4) = 4;  { Taste 3 gedrÅckt? }
          x:= cx;
          y:= dx
          end
end;

procedure Position;
begin
     with reg do begin
          ax:= 3;
          intr($33,reg);
          x:= cx;
          y:= dx
          end
end;


procedure CursorPositionSetzen;
begin
     with reg do begin
          ax:= 4;
          cx:= x;
          dx:= y;
          intr($33,reg)
          end
end;

function TasteGedrueckt;

begin
     with reg do begin
          if Gedrueckt
             then ax:= 5
             else ax:= 6;
          bx:= nummer;
          intr($33,reg);
          TasteGedrueckt:= (ax and (1 shl pred(nummer)))<>0;
          anzahl:= bx;
          letztes_x:= cx;     { Der letzte Tastendruck erfolgte bei ... }
          letztes_y:= dx
          end
end;

function Gedrueckt;
begin
     with reg do begin
          ax:= 5;
          bx:= nummer;
          intr($33,reg);
          Gedrueckt:= (ax and (1 shl pred(nummer)))<>0
          end
end;

function Losgelassen;
begin
     with reg do begin
          ax:= 6;
          bx:= nummer;
          intr($33,reg);
          Losgelassen:= (ax and (1 shl pred(nummer)))<>0
          end
end;

procedure MausNur;

begin
     with reg do begin
          ax:=7;
          cx:= a;
          dx:= c;
          intr($33,reg);
          ax:= 8;
          cx:= b;
          dx:= d;
          intr($33,reg)
          end
end;

procedure MausNie;

begin
     with reg do begin
          ax:= 16;
          cx:= a;
          dx:= b;
          si:= c;
          di:= d;
          intr($33,reg)
          end
end;

procedure Relativbewegung;

begin
     with reg do begin
          ax:= 11;
          intr($33,reg);
          delta_x:= cx;
          delta_y:= dx
          end
end;

procedure BewegungsEinheiten;

begin
     with reg do begin
          ax:= 15;
          cx:= x;
          dx:= y;
          intr($33,reg)
          end
end;

procedure DoppelteGeschwindigkeit;

begin
     reg.ax:= 19;
     reg.dx:= v;
     intr($33,reg)
end;


procedure EigenerGrafikCursor;
begin
     with reg do begin
          ax:= 9;
          bx:= gc_maske.u0;
          cx:= gc_maske.v0;
          dx:= ofs(gc_maske.BitMap);
          es:= seg(gc_maske.BitMap);
          intr($33,reg)
          end
end;

procedure EigenerTextCursor;
begin
     with reg do begin
          ax:= 10;
          if hard
             then bx:= 1
             else bx:= 0;
          cx:= und;
          dx:= entweder;
          intr($33,reg)
          end
end;
end.