unit fastgfx;

{****************************************************************************}

interface

{****************************************************************************}

uses crt;

{****************************************************************************}

const VGAMEM = $A000;
      VGA256 = $13;
      TXTMODE = $03;

type palette = array [0..255,0..2] of byte;

type image = record
	width, height : integer;
	data    : ^byte;
	dataseg : word;
	dataofs : word;
	pal     : palette;
end;

type imageptr = ^image;

type sprite = record
	x, y      : integer;
	pImage    : ^image;
	xvelocity : integer;
	yvelocity : integer;
	xmin,xmax : integer;
	ymin,ymax : integer;
	valid     : boolean;
end;

type DisplaySurface = ^byte;

procedure SetVideoMode(mode:integer);
procedure GetDisplay(var surface:DisplaySurface);
procedure FreeDisplay(var surface:DisplaySurface);

procedure GetPal(col:byte; var r,g,b:byte);
procedure SetPal(col,r,g,b:byte);
procedure GrabPal(var pal:palette);
procedure SendPal(pal:palette);

procedure FadeTo(slow:word; palt2:palette);
procedure FadeOutOne;

procedure LoadImage(var img:image; filename:string);
procedure DrawImage(x,y:integer; img:image; where:word);
procedure FreeImage(var img:image);

procedure DrawSprite(spr:sprite; where:word);
procedure MoveSprite(var spr:sprite);

procedure PutPixel(x,y:integer;col:byte;where:word);
procedure Blit(dest,src:word);
procedure Cls(col:byte; where:word);

function  keydown : Boolean;
function  fvalid(s:string):boolean;
procedure WaitRetrace;

{****************************************************************************}

implementation

{****************************************************************************}

procedure WaitRetrace;
var b : byte;
label l1, l2;
begin
l1:
     if port[$3da] and 8>0 then goto l1;
l2:
     if port[$3da] and 8=0 then goto l2;
end;

{****************************************************************************}

function keydown : Boolean;
begin
	keydown := (port[$60] < $80);
end;

{****************************************************************************}

procedure SetVideoMode(mode:integer); assembler;
asm
	mov ax, [mode]
	int $10
end;

{****************************************************************************}

procedure PutPixel(x,y:integer;col:byte;where:word); assembler;
asm
	mov ax, [where]
	mov es, ax
	mov di, [x]
	mov bx, [y]
end;

{****************************************************************************}

procedure LoadImage(var img : image; filename : string);
var	f        : file of byte;
	f2       : file of word;
	size     : longint;
	ptr      : longint;
	count    : word;
	r,g,b    : byte;
	chardata : byte;
	k,col    : word;
	MinX,MinY: word;
	MaxX,MaxY: word;

begin
	if fvalid(filename) then
	begin
          assign(f2, filename);
		reset(f2);
		seek(f2,2);
		read(f2,MinX);
		read(f2,MinY);
		read(f2,MaxX);
		read(f2,MaxY);
		close(f2);

		img.width  := MaxX-MinX+1;
		img.height := MaxY-MinY+1;

		assign(f,filename);
		reset(f);
		size:=filesize(f);

		{palette data}
		seek(f, size-768);

		for col:=0 to 255 do begin
			read(f,r);
			r:=r shr 2;
			read(f,g);
			g:=g shr 2;
			read(f,b);
			b:=b shr 2;
			img.pal[col,0] := r;
			img.pal[col,1] := g;
			img.pal[col,2] := b;
		end;
		{End of palette data}

		GetMem(img.data,img.width*img.height);
		img.dataseg := seg(img.data^);
		img.dataofs := ofs(img.data^);

		seek(f,128);
		ptr:=0;
		count:=0;
		while filepos(f) <> size-768 do begin
			read(f,chardata);
			if chardata<192 then begin
				mem[img.dataseg:img.dataofs+ptr] := chardata;
				inc(ptr);
			end else begin
				count := chardata - 192;
				read(f, chardata);
           		for k:=1 to count do begin
					mem[img.dataseg:img.dataofs+ptr] := chardata;
					inc(ptr);
				end;
			end;
		end;
		close(f);
	end else begin
		SetVideoMode(TXTMODE);
		writeln('Unable To Load ', filename, '!');
		repeat until port[$60] < $80;
		SetVideoMode(VGA256);
	end;
end;

{****************************************************************************}

procedure DrawSprite(spr:sprite; where:word);
begin
	if spr.valid then
		DrawImage(spr.x, spr.y, spr.pImage^, where);
end;

{****************************************************************************}

procedure MoveSprite(var spr:sprite);
begin
	if spr.valid then begin
		spr.x := spr.x + spr.xvelocity;
		spr.y := spr.y + spr.yvelocity;
		if (spr.x >= spr.xmax) then spr.x := spr.xmax;
		if (spr.y >= spr.ymax) then spr.y := spr.ymax;
		if (spr.x <= spr.xmin) then spr.x := spr.xmin;
		if (spr.y <= spr.ymin) then spr.y := spr.ymin;
	end;
end;

{****************************************************************************}

procedure DrawImage(x,y:integer; img:image; where:word);

var	width, height : integer;
	dataseg, dataofs : word;

label ForEachRow, ForEachCol, NoDraw;

begin
	width   := img.width;
	height  := img.height;
	dataseg := img.dataseg;
	dataofs := img.dataofs;

	asm
	     push ds
		mov  ax, [where]
		mov  es, ax
		mov  di, [x]
		mov  bx, [y]
		mov  dx, bx
	     shl  bx, 6
		shl  dx, 8
		add  bx, dx
		add  di, bx

		mov  dx, [width]
		mov  cx, [height]

		mov  si, [dataofs]
		mov  ax, [dataseg]
		mov  ds, ax

		ForEachRow:
			push cx
			mov  cx, dx

			ForEachCol:
				xor  ax, ax
				mov  al, [ds:si]
				or   al, al
				jz   NoDraw
				movsb
				dec  di
				dec  si
				NoDraw:
				inc  di
				inc  si
				loop ForEachCol

		add  di, 320
		sub  di, dx
		pop  cx
		loop ForEachRow
		pop  ds
	end;
end;

{****************************************************************************}

procedure FreeImage(var img : image);
begin
	freemem(img.data, img.width*img.height);
end;

{****************************************************************************}

procedure getpal(col:byte; var r,g,b:byte);
begin
	port[$3c7]:=col;
	r:=port[$3c9];
	g:=port[$3c9];
	b:=port[$3c9];
end;

{****************************************************************************}

procedure setpal(col,r,g,b:byte);
begin
	port[$3c8]:=col;
	port[$3c9]:=r;
	port[$3c9]:=g;
	port[$3c9]:=b;
end;

{****************************************************************************}

function fvalid(s:string):boolean;
var f:file;
begin
	assign(f,s);
	{$i-}
	reset(f);
	close(f);
	{$i+}
	if ioresult <> 0 then fvalid := false
	else fvalid := true;
end;

{****************************************************************************}

procedure GetDisplay(var surface:DisplaySurface);
begin
	getmem(surface, 64000);
end;

{****************************************************************************}

procedure FreeDisplay(var surface:DisplaySurface);
begin
	freemem(surface, 64000);
end;

{****************************************************************************}

procedure Blit(dest, src : word); assembler;
asm
	push ds
	mov  ax, [dest]
	mov  es, ax
	mov  ax, [src]
	mov  ds, ax
	xor  di, di
	xor  si, si
	mov  cx, 32000
	rep  movsw
	pop  ds
end;

{****************************************************************************}

procedure Cls(col:byte; where:word); assembler;
asm
	mov ax, [where]
	mov es, ax
	xor di, di
     mov ah, [col]
	mov al, ah
	mov cx, 32000
	rep stosw
end;

{****************************************************************************}

procedure GrabPal(var pal:palette);
var i:integer;
begin
	for i := 0 to 255 do begin
		getpal(i, pal[i,0], pal[i,1], pal[i,2]);
	end;
end;

{****************************************************************************}

procedure SendPal(pal:palette);
var i:integer;
begin
	for i := 0 to 255 do begin
		setpal(i, pal[i,0], pal[i,1], pal[i,2]);
	end;
end;

{****************************************************************************}

procedure FadeTo(slow : WORD; palt2 : palette);
var n, i, j : byte;
    palt : palette;
begin
     for n:=0 to 255 do
          getpal(n,palt[n,0],palt[n,1],palt[n,2]);

     for i:=0 to 63 do begin

          delay(slow);
          waitretrace;

          j:=63-i;

          for n:=0 to 255 do
              setpal(n,(palt2[n,0]*i+palt[n,0]*j) div 63,
                    (palt2[n,1]*i+palt[n,1]*j) div 63,
                    (palt2[n,2]*i+palt[n,2]*j) div 63); {Super Fade!!!}
     end;
end;

{****************************************************************************}

procedure FadeOutOne;

var n, i  : byte;
    r,g,b : byte;

begin
     for n:=0 to 255 do
     begin
          getpal(n,r,g,b);
          if r>0 then dec(r);
          if g>0 then dec(g);
          if b>0 then dec(b);
          setpal(n,r,g,b);
	end;
end;

{****************************************************************************}

begin
end.

{****************************************************************************}
