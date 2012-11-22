{****************************************************************************}

program Ozone2;

{****************************************************************************}

uses mousenfo, fastgfx, crt;

{****************************************************************************}

var 	running     : boolean;
	counter     : integer;
	counter2    : integer;
	EnemyIndex  : integer;

	backbuffer  : DisplaySurface;
	buffermem   : word;
	bgbuffer    : DisplaySurface;
	bgmem       : word;

	GoodShipPic : image;
	AlienPic    : image;
	EnemyPic    : image;
	ShotPic     : image;

	GoodShip    : sprite;
	Aliens      : array [0..27] of sprite;
	Enemy       : sprite;
 	GoodShot    : sprite;
     EnemyShot   : sprite;

	EnemyLife   : integer;
	GoodLife    : integer;

	letters     : array [0..37] of imageptr;

	speed       : integer;

{****************************************************************************}

function CharToNum(c:char):integer;
begin
	if  (c >= 'A') and (c <= 'Z') then
		CharToNum := integer(c) - integer('A')
	else
		if  (c >= 'a') and (c <= 'z') then
			CharToNum := integer(c) - integer('a')
		else
			if (c >= '0') and (c <='9') then
				CharToNum := integer(c) - integer('0') + 26
			else
				if c = ':' then CharToNum := 36
				else CharToNum := 37;
end;

{****************************************************************************}

procedure DrawString(x,y:integer; s:string; where:word);
var i:integer;
begin
	for i := 1 to length(s) do
	begin
		DrawImage(x + ((i-1) shl 4), y, letters[CharToNum(s[i])]^, where);
	end;
end;

{****************************************************************************}

procedure LoadLetters;
var i:integer; s:string;
begin
	for i := 0 to 25 do begin
		new(letters[i]);
		s := char(integer('A')+i);
		s := s + '.pcx';
		LoadImage(letters[i]^, s);
	end;

	for i := 26 to 35 do begin
		new(letters[i]);
		s := char(integer('0')+i-26);
		s := s + '.pcx';
		LoadImage(letters[i]^, s);
	end;

	new(letters[36]);
	LoadImage(letters[36]^, 'colon.pcx');

	new(letters[37]);
	LoadImage(letters[37]^, 'space.pcx');
end;

{****************************************************************************}

procedure destroy;
var i:integer;
begin
	SetVideoMode(TXTMODE);
	FreeDisplay(backbuffer);

	FreeImage(GoodShipPic);
	FreeImage(AlienPic);
	FreeImage(EnemyPic);
	FreeImage(ShotPic);

	for i:= 0 to 36 do begin
		FreeImage(letters[i]^);
		dispose(letters[i]);
	end;
end;

{****************************************************************************}

procedure input;
var mouse : MouseInfo;
begin
     if GoodShip.valid then begin

		GetMouseStatus(mouse);
		GoodShip.x := mouse.x shr 1;
		if GoodShip.x > 304 then GoodShip.x := 304;

		if mouse.button1 and not GoodShot.Valid then begin
     		with GoodShot do begin
				x := GoodShip.x + 3;
				y := GoodShip.y - 6;
				xmin := x;
				xmax := x;
				GoodShot.Valid := true;
			end;
		end;
	end;
end;

{****************************************************************************}

procedure paint;
var i:integer; s:string;
begin

	blit(buffermem, bgmem);

	s := char(integer('0')+GoodLife);
	DrawString(  0, 0, 'Ships:', buffermem);
	DrawString(100, 0, s, buffermem);

	s := char(integer('0')+(EnemyLife div 10));
	s := s+char(integer('0')+(EnemyLife mod 10));
	DrawString(191, 0, 'Enemy:', buffermem);
	DrawString(291, 0, s, buffermem);

	DrawSprite(GoodShip, buffermem);

	for i := 0 to 27 do
		DrawSprite(Aliens[i], buffermem);

	DrawSprite(Enemy, buffermem);

	if GoodShot.Valid then DrawSprite(GoodShot, buffermem);

	blit(VGAMEM, buffermem);

end;

{****************************************************************************}

procedure MoveAliens;
var i : integer;
begin
	for i := 0 to 27 do begin
		MoveSprite(Aliens[i]);
		if Aliens[i].x = Aliens[i].xmax then Aliens[i].xvelocity:=-1;
		if Aliens[i].x = Aliens[i].xmin then Aliens[i].xvelocity:=1;
		if Aliens[i].y = Aliens[i].ymax then Aliens[i].yvelocity:=-1;
		if Aliens[i].y = Aliens[i].ymin then Aliens[i].yvelocity:=1;
	end;
end;

{****************************************************************************}

var delta : integer;

procedure MoveEnemy;
begin
	if EnemyIndex = 10 then begin
		delta := (1-random(3)) shl 1;
		EnemyIndex := 0;
	end;

	enemy.x := enemy.x + delta;
	inc(EnemyIndex);
	if enemy.x > 300 then enemy.x := 300;
	if enemy.x < 1   then enemy.x := 1;
end;

{****************************************************************************}

procedure MoveGoodShot;
begin
	if GoodShot.Valid then begin
		MoveSprite(GoodShot);
		if GoodShot.y = GoodShot.ymin then
			GoodShot.Valid := false;
	end;
end;

{****************************************************************************}

procedure MoveEnemyShot;
var i:integer;
begin
	if EnemyShot.Valid then begin
		MoveSprite(EnemyShot);
		if EnemyShot.y = EnemyShot.ymax then
			EnemyShot.Valid := false;
	end else begin
		i := random(150);
		if i=20 then begin
			with EnemyShot do begin
				x := enemy.x;
				y := enemy.y;
				xmax := x;
				xmin := x;
				valid := true;
			end;
		end;
	end;
end;

{****************************************************************************}

procedure AnimateShip;
var i:longint; temp,temp2:integer; {r,g,b:byte; rt,gt,bt:byte; }
begin
	if (counter2 and $1F) < 16 then begin
		temp := counter2 and $0F;

		for i := 240 to 239+temp do begin
			temp2 := (240+temp-i) shl 2;
			SetPal(i, temp2, temp2, temp2);
		end;

		SetPal(240+temp, 0, 0, 0);

		for i := 241+temp to 255 do begin
			temp2 := (i-(240+temp)) shl 2;
			SetPal(i, temp2, temp2, temp2);
		end;

		inc(counter2);
	end else begin
		temp := (counter2 and $0F);

		for i := 240 to 239+temp do begin
			temp2 := 63-(240+temp-i) shl 2;
			SetPal(i, temp2, temp2, temp2);
		end;

		SetPal(240+temp, 63, 63, 63);

		for i := 241+temp to 255 do begin
			temp2 := 63-(i-(240+temp)) shl 2;
			SetPal(i, temp2, temp2, temp2);
		end;

		inc(counter2);
	end;

	for i := 63999 downto 320 do
		mem[bgmem:i] := mem[bgmem:i-320];

	for i := 319 downto 0 do
		mem[bgmem:i] := 0;

	for i := 0 to random(15) do
		mem[bgmem:random(320)] := random(100)+1;

	for i := 63999 downto 320 do
		mem[bgmem:i] := mem[bgmem:i-320];

	for i := 319 downto 0 do
		mem[bgmem:i] := 0;

	for i := 0 to random(15) do
		mem[bgmem:random(320)] := random(100)+1;

end;

{****************************************************************************}

procedure MoveAll;
begin
	MoveAliens;
	MoveEnemy;
	MoveGoodShot;
	AnimateShip;

	if counter mod 10 = 0 then
		with Aliens[random(28)] do begin
			if y >= 160 then y := random(100);
			valid := not valid;
		end;

end;

{****************************************************************************}

function inArea(x, y : integer; spr : sprite) : boolean;
var right, bottom : integer;
begin
     if (not spr.valid) then inArea := false
	else begin
		right  := spr.x + spr.pImage^.width;
		bottom := spr.y + spr.pImage^.height;

		inArea := (x >= spr.x) and
				(x <= right) and
				(y >= spr.y) and
				(y <= bottom);
	end;
end;

{****************************************************************************}

function Overlap(spr1, spr2 : sprite) : boolean;
var right, bottom : integer;
begin

	if (not spr1.valid) or (not spr2.valid) then Overlap := false
	else begin
		right  := spr1.x + spr1.pImage^.width;
		bottom := spr1.y + spr1.pImage^.height;

		Overlap := inArea(spr1.x+5, spr1.y+5, spr2) or
				 inArea(right -5, spr1.y+5, spr2) or
				 inArea(spr1.x+5, bottom-5, spr2) or
				 inArea(right -5, bottom-5, spr2);
	end;
end;

{****************************************************************************}

const	SPEAKER_PORT	= $61;
		PIT_CONTROL	= $43;
		PIT_CHANNEL_2	= $42;
		PIT_FREQ		= $1234DD;

{****************************************************************************}

procedure Sound(frequency:word; length:integer);
var counter3:word;
begin
	counter3 := PIT_FREQ div frequency;
	Port[PIT_CONTROL] := $B6;
	Port[PIT_CHANNEL_2] := Lo(counter3);
	Port[PIT_CHANNEL_2] := Hi(counter3);
	Port[SPEAKER_PORT] := Port[SPEAKER_PORT] or 3;
	delay(length);
	Port[SPEAKER_PORT] := Port[SPEAKER_PORT] and $FC;
end;

{****************************************************************************}

procedure AlienHit(i : integer);
begin
	Aliens[i].valid := false;
	GoodShot.valid := false;
	Sound(500, 250);
end;

{****************************************************************************}

procedure GoodShipHit;
var portval : byte; i : integer;
begin
	dec(GoodLife);
	GoodShip.valid := false;
	Sound(500, 300);
end;

{****************************************************************************}

procedure EnemyHit;
begin
	dec(EnemyLife);
	Enemy.valid := false;
	Sound(500, 300);
end;

{****************************************************************************}

procedure CheckHits;
var i : integer;
begin
	for i := 0 to 27 do begin
		if GoodShot.valid then
		if Overlap(GoodShot, Aliens[i]) then AlienHit(i);
		if Overlap(GoodShip, Aliens[i]) then GoodShipHit;
	end;

	if Overlap(GoodShot, Enemy) then EnemyHit;
end;

{****************************************************************************}

procedure init;
var i,j : longint;
begin
	running := true;
	counter := 0;
	EnemyIndex := 0;
	EnemyLife := 15;
	GoodLife  := 5;

	LoadLetters;

	LoadImage(GoodShipPic, 'goodship.pcx');
	LoadImage(AlienPic, 'alien.pcx');
	LoadImage(EnemyPic, 'enemy.pcx');
	LoadImage(ShotPic, 'shot.pcx');

	goodship.x := 160;
	goodship.y := 180;
	goodship.pImage := addr(GoodShipPic);
	goodship.valid := true;

	enemy.x := 160;
	enemy.y := 1;
	enemy.pImage := addr(EnemyPic);
	enemy.valid := true;

	for i := 0 to 27 do begin
		aliens[i].x := (40*(i mod 7))+20 + (((i div 7) and 1)*20);
		aliens[i].y := (30*(i div 7))+40;
  		aliens[i].xvelocity := random(2)*-2+1;
		aliens[i].yvelocity := random(2)*-2+1;
		aliens[i].xmin := 4;	{aliens[i].x;}
		aliens[i].xmax := 300;	{aliens[i].x+20;}
		aliens[i].ymin := 4;	{aliens[i].y-20;}
		aliens[i].ymax := 180;	{aliens[i].y+40;}
		aliens[i].pImage := addr(AlienPic);
		aliens[i].valid := true;
	end;

	GoodShot.valid   := false;
	GoodShot.yvelocity := -6;
	GoodShot.xvelocity := 0;
	GoodShot.ymin := 0;
 	GoodShot.ymax := 170;
 	GoodShot.pImage := addr(ShotPic);

	randomize;

	GetDisplay(backbuffer);
	buffermem := seg(backbuffer^);
	GetDisplay(bgbuffer);
	bgmem := seg(bgbuffer^);

	SetVideoMode(VGA256);
	ResetMouse;

	enemy.pImage^.pal[0,0] := 0;
	enemy.pImage^.pal[0,1] := 0;
	enemy.pImage^.pal[0,2] := 0;

	for i := 1 to 100 do begin

		enemy.pImage^.pal[i,0] := 0;
		enemy.pImage^.pal[i,1] := 0;
		enemy.pImage^.pal[i,2] := (i*62) div 100;

	end;

	for i := 0 to 63999 do
		mem[bgmem:i] := (i div 640) + 1;

end;

{****************************************************************************}

procedure oldgame;
var i,j:integer; mouse:MouseInfo; key:char; s:string;
begin
	with EnemyShot do begin
		xvelocity := 0;
		yvelocity := 6;
		ymin := y;
		ymax := 184;
		pImage := Addr(ShotPic);
		valid := false;
	end;

	for i := 0 to 27 do begin
		aliens[i].x := (40*(i mod 7))+20;
		aliens[i].y := (30*(i div 7))+40;
  		aliens[i].xvelocity := random(2)*-2+1;
		aliens[i].yvelocity := random(2)*-2+1;
		aliens[i].xmin := aliens[i].x;
		aliens[i].xmax := aliens[i].x+20;
		aliens[i].ymin := aliens[i].y;
		aliens[i].ymax := aliens[i].y;
		aliens[i].pImage := addr(AlienPic);
		aliens[i].valid := true;
	end;

	for i := 0 to 255 do setpal(i, 0, 0, 0);

	delay(5000);

     blit(buffermem, bgmem);

	DrawString(48, 65, 'The aliens are', buffermem);
	DrawString(40, 85, 'using our ozone', buffermem);
	DrawString(48,105, 'to power their', buffermem);
	DrawString(80,125,   'mothership', buffermem);

	blit(vgamem, buffermem);

	FadeTo(100, enemy.pImage^.pal);

	readkey;

     blit(buffermem, bgmem);

	DrawString(34,  70, 'You must destroy', buffermem);
	DrawString(50,  90, 'the mothership', buffermem);
	DrawString(50, 110, 'and save Earth', buffermem);

	blit(vgamem, buffermem);

	readkey;

     blit(buffermem, bgmem);

	DrawString(30,  70, 'The Mothership:', buffermem);
	DrawString(30,  90, ' Ozone Critter:', buffermem);
	DrawString(30, 110, '     Your Ship:', buffermem);

	DrawImage(270, 70, EnemyPic, buffermem);
	DrawImage(270, 90, AlienPic, buffermem);
	DrawImage(270,110, GoodShipPic, buffermem);

	blit(vgamem, buffermem);

	readkey;

	for i := 0 to 63 do begin
		fadeoutone;
		delay(200);
	end;

     blit(buffermem, bgmem);
	DrawSprite(GoodShip, buffermem);

	for i:= 0 to 27 do begin
		DrawSprite(Aliens[i], buffermem);
	end;

	DrawSprite(enemy, buffermem);

	for i := 0 to 255 do setpal(i, 0, 0, 0);
	blit(vgamem, buffermem);
	FadeTo(100, enemy.pImage^.pal);

	repeat
		MoveAliens;
		MoveEnemy;
		MoveGoodShot;
		MoveEnemyShot;

		GetMouseStatus(mouse);
		GoodShip.x := mouse.x shr 1;
		if GoodShip.x > 304 then GoodShip.x := 304;

		if mouse.button1 and not GoodShot.Valid then begin
     		with GoodShot do begin
				x := GoodShip.x + 3;
				y := GoodShip.y - 6;
				xmin := x;
				xmax := x;
				GoodShot.Valid := true;
			end;
		end;

	     blit(buffermem, bgmem);

		if random(100)=10 then aliens[random(28)].valid := true;

		DrawSprite(GoodShip, buffermem);

		for i:= 0 to 27 do begin
			DrawSprite(Aliens[i], buffermem);
		end;

		DrawSprite(enemy, buffermem);
		DrawSprite(goodshot, buffermem);
		DrawSprite(enemyshot, buffermem);

		s := char(integer('0')+GoodLife);
		DrawString(  0, 0, 'Ships:', buffermem);
		DrawString(100, 0, s, buffermem);

		s := char(integer('0')+(EnemyLife div 10));
		s := s+char(integer('0')+(EnemyLife mod 10));
		DrawString(191, 0, 'Enemy:', buffermem);
		DrawString(291, 0, s, buffermem);

		blit(vgamem, buffermem);

		for i := 0 to 27 do begin
              	if Overlap(GoodShot, Aliens[i]) then begin
				AlienHit(i);
				inc(EnemyLife);
			end;

              	if Overlap(EnemyShot, Aliens[i]) then begin
				AlienHit(i);
				GoodShot.valid := true;
				EnemyShot.valid := false;
				inc(EnemyLife);
			end;

			if Overlap(GoodShip, EnemyShot) then begin
				GoodShipHit;
				EnemyShot.valid := false;
				if GoodLife > 0 then GoodShip.valid := true;
			end;
			if Overlap(GoodShip, Aliens[i]) then begin
				GoodShipHit;
				Aliens[i].valid := false;
				if GoodLife > 0 then GoodShip.valid := true;
			end;
		end;

		if Overlap(GoodShot, Enemy) then begin
			EnemyHit;
			if EnemyLife > 0 then enemy.valid := true;
		end;

		if not GoodShip.valid then begin

			for i := 0 to 54 do begin
				fadeoutone;
				delay(200);
			end;

			{blit(buffermem, bgmem);}

			setpal(213, enemy.pImage^.pal[213,0],
					  enemy.pImage^.pal[213,1],
					  enemy.pImage^.pal[213,2]);

			DrawString(32, 80, 'You have allowed', buffermem);
			DrawString(2, 100, 'the alien mothership', buffermem);
			DrawString(32, 120, 'to destory Earth', buffermem);

			blit(vgamem, buffermem);

			{FadeTo(2000, enemy.pImage^.pal);}

			readkey;

			for i := 0 to 63 do begin
				fadeoutone;
				delay(500);
			end;

			halt;
		end;

		delay(10000-speed);

		if keypressed then key:=readkey;

		if integer(key) = $1B then begin
			for i := 0 to 63 do begin
				fadeoutone;
				delay(1500);
			end;
			destroy;
			halt;
		end;

	until (not enemy.valid) or (not goodship.valid);

	for i := 0 to 54 do begin
		fadeoutone;
		delay(500);
	end;

	setpal(213, enemy.pImage^.pal[213,0],
			  enemy.pImage^.pal[213,1],
			  enemy.pImage^.pal[213,2]);

	DrawString(40,50,'Now Destroy the',vgamem);
	DrawString(48,70,'  mothership',vgamem);
	readkey;
	DrawString(24,110,' It will use our',vgamem);
	DrawString(24,130,'ozone against you',vgamem);
	readkey;

	FadeTo(100, enemy.pImage^.pal);

	delay(5000);

	for i := 0 to 27 do begin
		while aliens[i].x < ((40*(i mod 7))+20 + (((i div 7) and 1)*20)) do
		begin
			inc(aliens[i].x);
		     blit(buffermem, bgmem);
			DrawSprite(GoodShip, buffermem);

			for j := 0 to 27 do begin
				DrawSprite(Aliens[j], buffermem);
			end;

			DrawSprite(enemy, buffermem);
			DrawSprite(goodshot, buffermem);

			blit(vgamem, buffermem);
			{delay(350);}
		end;

		while aliens[i].x > ((40*(i mod 7))+20 + (((i div 7) and 1)*20)) do
		begin
			dec(aliens[i].x);
		     blit(buffermem, bgmem);
			DrawSprite(GoodShip, buffermem);

			for j := 0 to 27 do begin
				DrawSprite(Aliens[j], buffermem);
			end;

			DrawSprite(enemy, buffermem);
			DrawSprite(goodshot, buffermem);

			blit(vgamem, buffermem);
			delay(350);
		end;

		aliens[i].xmin := 4;	{aliens[i].x;}
		aliens[i].xmax := 300;	{aliens[i].x+20;}
		aliens[i].ymin := 4;	{aliens[i].y-20;}
		aliens[i].ymax := 180;	{aliens[i].y+40;}
	end;
end;

{****************************************************************************}

var key : char;
    i   : integer;

begin

	write('What speed would you like (0-10000)? ');
	read(speed);

	if speed < 0   then speed := 0;
	if speed > 10000 then speed := 10000;

	init;

	oldgame;
	EnemyLife := 15;
	GoodLife := 5;

	{cls(0, buffermem);
	for i := 0 to 255 do setpal(i, 0, 0, 0);
	paint;
	blit(vgamem, buffermem);
	FadeTo(100, enemy.pImage^.pal);}

	repeat

		repeat

			input;
			paint;

			if counter mod 3 = 0 then begin
				MoveAll;
				CheckHits;
			end;

			if counter mod 64 = 0 then Enemy.valid := true;

			inc(counter);

			running := (GoodLife > 0) and (EnemyLife > 0);

		until keypressed or not running;

		GoodShip.valid := true;

		if keypressed then begin
			key := readkey;
			if integer(key) = $1B then running := false;
		end else begin

          	i := 0;
			while i <= 64 do begin
				paint;
				if counter mod 7 = 0 then begin
					MoveAliens;
					MoveEnemy;
					MoveGoodShot;
					if counter mod 28 =0 then begin
						FadeOutOne;
						inc(i);
					end;
				end;
				inc(counter);
			end;
		end;

	until not running;

	for i := 0 to 54 do begin
		fadeoutone;
		delay(200);
	end;

	if GoodLife = 0 then begin
		cls(0,vgamem);
		setpal(213, enemy.pImage^.pal[213,0],
				  enemy.pImage^.pal[213,1],
				  enemy.pImage^.pal[213,2]);

		DrawString(54, 80,'You Have been',vgamem);
		DrawString(54,100,'  destroyed',vgamem);
	end else
		if EnemyLife = 0 then
		begin
		cls(0,vgamem);
		setpal(213, enemy.pImage^.pal[213,0],
				  enemy.pImage^.pal[213,1],
				  enemy.pImage^.pal[213,2]);

		DrawString(0,80,'You have saved earth',vgamem);

		end else begin
			cls(0,vgamem);
     		setpal(213, enemy.pImage^.pal[213,0],
     				  enemy.pImage^.pal[213,1],
					  enemy.pImage^.pal[213,2]);

			DrawString(45,85,'Goodbye Quiter',vgamem);
		end;

	readkey;
	destroy;
end.

{****************************************************************************}
