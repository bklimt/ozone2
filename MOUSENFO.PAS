
unit mousenfo;

interface

type

MouseInfo = record
	x : integer;
	y : integer;
	button1 : Boolean;
	button2 : Boolean;
end;

procedure EnableMouse;
procedure DisableMouse;
procedure GetMouseStatus(var mi : MouseInfo);
procedure SetXRange(min, max : integer);
procedure SetYRange(min, max : integer);
procedure ResetMouse;

implementation

procedure GetMouseStatus(var mi : MouseInfo);
var x, y , button1, button2: integer;
begin
	asm
     	mov ax, 3
          int $33
          mov [x], cx
          mov [y], dx
		mov ax, bx
		and ax, 1
		and bx, 2
		mov [button1], ax
		mov [button2], bx
     end;

     mi.x := x;
     mi.y := y;

     if button1 <> 0 then mi.button1 := true
     else mi.button1 := false;

     if button2 <> 0 then mi.button2 := true
     else mi.button2 := false;
end;

procedure EnableMouse; assembler;
asm
	mov ax, 1
	int $33
end;

procedure DisableMouse; assembler;
asm
	mov ax, 2
	int $33
end;

procedure SetXRange(min, max : integer); assembler;
asm
	mov ax, 7
	mov cx, [min]
	mov dx, [max]
	int $33
end;

procedure SetYRange(min, max : integer); assembler;
asm
	mov ax, 8
	mov cx, [min]
	mov dx, [max]
	int $33
end;

procedure ResetMouse; assembler;
asm
	mov ax, 0
	int $33
end;

begin
end.