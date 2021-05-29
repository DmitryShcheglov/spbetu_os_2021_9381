ASSUME CS:CODE, DS:DATA, SS:LAB_STACK

LAB_STACK SEGMENT STACK
	DW 64 DUP(?)
LAB_STACK ENDS

CODE SEGMENT

INTERRUPTION_TIMER PROC FAR
	jmp START

	pspAddres0 dw 0
	pspAddres1 dw 0
	keepCs dw 0
	keepIp dw 0

	keepSs dw 0
	keepSp dw 0
	keepAx dw 0

	interruptionTimerSet dw 0FEDCh
	intCount db 'Interrupts call count: 0000  $'
	newstack dw 64 dup(?)

START:
	mov keepSp, sp
	mov keepAx, ax
	mov keepSs, ss
	mov sp, offset START
	mov ax, seg newstack
	mov ss, ax

	push ax
	push bx
	push cx
	push dx

	mov ah, 03h
	mov bh, 00h
	int 10h
	push dx

	mov ah, 02h
	mov bh, 00h
	mov dx, 0220h
	int 10h

	push si
	push cx
	push ds
	mov ax, seg intCount
 	mov ds, ax
 	mov si, offset intCount
 	add si, 27
 	mov cx, 4

 loop_m:
 	mov ah,[si]
 	inc ah
 	mov [si], ah
 	cmp ah, 3ah
 	jne PRINT_TIMER
 	mov ah, 30h
 	mov [si], ah	
 	dec si
 	loop loop_m

PRINT_TIMER:
    pop ds
    pop cx
	pop si

	push es
    push bp
    mov ax, SEG intCount
    mov es, ax
    mov ax, offset intCount
    mov bp, ax
    mov ah, 13h
    mov al, 00h
    mov cx, 1Dh
    mov bh, 0
    int 10h
    pop bp
	pop es

	pop dx
	mov ah, 02h
	mov bh, 0h
	int 10h

	pop dx
	pop cx
	pop bx
	pop ax

    mov ss, keepSs
    mov ax, keepAx
    mov sp, keepSp

	iret
INTERRUPTION_TIMER ENDP

MEMORY_AREA:

IS_INT_SETTED PROC NEAR
	push bx
	push dx
	push es

	mov ah, 35h
	mov al, 1Ch
	int 21h

	mov dx, es:[bx + 17]
	cmp dx, 0fedch
	je INT_IS_SET
	mov al, 00h
	jmp POP_REG

INT_IS_SET:
	mov al, 01h
	jmp POP_REG

POP_REG:
	pop es
	pop dx
	pop bx

	ret
IS_INT_SETTED ENDP

IS_THERE_COMMAND PROC NEAR
	push es

	mov ax, pspAddres0
	mov es, ax

	mov bx, 0082h

	mov al, es:[bx]
	inc bx
	cmp al, '/'
	jne NULL_CMD

	mov al, es:[bx]
	inc bx
	cmp al, 'u'
	jne NULL_CMD

	mov al, es:[bx]
	inc bx
	cmp al, 'n'
	jne NULL_CMD
	
	mov al, 0001h
	
NULL_CMD:
	pop es

	ret
	
IS_THERE_COMMAND ENDP


LOAD_INT PROC NEAR
	push ax
	push bx
	push dx
	push es

	mov ah, 35h
	mov al, 1Ch
	int 21h

	mov keepIp, bx
	mov keepCs, es

	push ds
    mov dx, offset INTERRUPTION_TIMER
    mov ax, seg INTERRUPTION_TIMER
    mov ds, ax

    mov ah, 25h
    mov al, 1Ch
    int 21h
	pop ds

	mov dx, offset INT_IS_LOADING
	call PRINT

	pop es
	pop dx
	pop bx
	pop ax

	ret
LOAD_INT ENDP


DELETE_INT PROC NEAR
	push ax
	push bx
	push dx
	push es

	mov ah, 35h
	mov al, 1Ch
	int 21h

	cli
	push ds
    mov dx, es:[bx + 9]
    mov ax, es:[bx + 7]

    mov ds, ax
    mov ah, 25h
    mov al, 1Ch
    int 21h
	pop ds
	sti

	mov dx, offset INT_WAS_RESTORED
	call PRINT

	push es
    mov cx, es:[bx + 3]
    mov es, cx
    mov ah, 49h
    int 21h
	pop es

	mov cx, es:[bx + 5]
	mov es, cx
	int 21h

	pop es
	pop dx
	pop bx
	pop ax

	ret
DELETE_INT ENDP

PRINT PROC NEAR
	push ax
	mov ah, 09h
	int	21h
	pop ax
	ret
PRINT ENDP

MAIN PROC FAR
	mov bx, 02Ch
	mov ax, [bx]
	mov pspAddres1, ax
	mov pspAddres0, ds
	sub ax, ax
	xor bx, bx

	mov ax, DATA
	mov ds, ax

	call IS_THERE_COMMAND
	cmp al, 01h
	je CALL_DEL_INT

	call IS_INT_SETTED
	cmp al, 01h
	jne INTERRUPTI0N_IS_NOT_LOADED

	mov dx, offset INT_IS_LOADED
	call PRINT
	jmp EXIT

	mov ah,4Ch
	int 21h

INTERRUPTI0N_IS_NOT_LOADED:
	call LOAD_INT

	mov dx, offset MEMORY_AREA
	mov cl, 04h
	shr dx, cl
	add dx, 1Bh

	mov ax, 3100h
	int 21h

CALL_DEL_INT:
	call IS_INT_SETTED
	cmp al, 00h
	je INT_IS_NOT_SETTED
	call DELETE_INT
	jmp EXIT

INT_IS_NOT_SETTED:
	mov dx, offset INT_NOT_SETTED
	call PRINT
    jmp EXIT

EXIT:
	mov ah, 4Ch
	int 21h
	
MAIN ENDP

CODE ENDS

DATA SEGMENT
	INT_NOT_SETTED      db      "int not loaded",       0dh, 0ah, '$'
	INT_WAS_RESTORED    db      "int was restored",     0dh, 0ah, '$'
	INT_IS_LOADED       db      "int is loaded",        0dh, 0ah, '$'
	INT_IS_LOADING      db      "int is loading",       0dh, 0ah, '$'
DATA ENDS

END MAIN