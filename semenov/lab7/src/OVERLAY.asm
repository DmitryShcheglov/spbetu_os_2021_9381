DSEG segment
DSEG ENDS

CSEG segment
OVERLAY PROC FAR
ASSUME CS:CSEG, DS:DSEG
PUSH ds 
MOV ax, DSEG
MOV ds, ax
mov ax, cs
mov bx, 10h
del: div bx
push dx
xor dx, dx
inc cx
test ax, ax
jnz del

lp:
pop ax
and al, 0Fh
cmp al, 09
jbe next
add al, 07
next:  
	add al, 30h
	mov dl, al
	mov ah, 02h
	int 21h
	loop lp
	POP ds ;восстанавливаем DS при завершении
	RETF
OVERLAY ENDP
CSEG ENDS
END