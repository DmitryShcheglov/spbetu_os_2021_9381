 TESTPC	segment
		ASSUME CS: TESTPC, DS: TESTPC, ES:nothing, SS:nothing
	 ORG	100h

Start:
	jmp Begin

	Available_memory 	db 'Available memory:         b$'
	Extended_memory 	db 'Extended memory:          Kb$'
	MCB	              db 'List of MCB:$'
	MCBtype db 'MCB type: 00h$'
	PSP_address 	db 'PSP adress: 0000h$'
	size_s 	db 'Size:          b$'
  Endl	db  13, 10, '$'
  Tab		db 	9,'$'

TETR_TO_HEX PROC near
    and 	al, 0Fh
    cmp 	al, 09
    jbe 	next
    add 	al, 07
Next:
    add 	al, 30h
    ret
   TETR_TO_HEX endp

BYTE_TO_HEX PROC near
    push 	cx
    mov 	ah, al
    call 	TETR_TO_HEX
    xchg 	al, ah
    mov 	cl, 4
    shr 	al, cl
    call 	TETR_TO_HEX
    pop 	cx
    ret
  BYTE_TO_HEX  endp

WRD_TO_HEX PROC near
   push BX
   mov BH,AH
   call BYTE_TO_HEX
   mov [DI],AH
   dec DI
   mov [DI],AL
   dec DI
   mov AL,BH
   call BYTE_TO_HEX
   mov [DI],AH
   dec DI
   mov [DI],AL
   pop BX
   ret
WRD_TO_HEX ENDP

BYTE_TO_DEC PROC near
   push CX
   push DX
   xor AH,AH
   xor DX,DX
   mov CX,10

loop_bd:
   div CX
   or DL,30h
   mov [SI],DL
   dec SI
   xor DX,DX
   cmp AX,10
   jae loop_bd
   cmp AL,00h
   je end_l
   or AL,30h
   mov [SI],AL

end_l:
   pop DX
   pop CX
   ret
BYTE_TO_DEC ENDP

WRD_TO_DEC PROC near
    push 	cx
    push 	dx
    mov  	cx, 10
wloop_bd:
    div 	cx
    or  	dl, 30h
    mov 	[si], dl
    dec 	si
	xor 	dx, dx
    cmp 	ax, 10
    jae 	wloop_bd
    cmp 	al, 00h
    je 		wend_l
    or 		al, 30h
    mov 	[si], al
wend_l:
    pop 	dx
    pop 	cx
    ret
WRD_TO_DEC endp

;вывод строки
PRINT proc near
    push 	ax
    mov 	ah, 09h
    int 	21h
    pop 	ax
    ret
   PRINT endp

;print a symbol
Print_symb proc near
	push	ax
	mov		ah, 02h
	int		21h
	pop		ax
	ret
Print_symb endp


Begin:
	mov 	ah, 4Ah      ;amount of available memory
	mov 	bx, 0FFFFh   ; max amount
	int 	21h

	mov dx, 0
	mov 	ax, bx
	mov 	cx, 10h
	mul 	cx

	lea  	si,	Available_memory
  add si, 24
	call 	wrd_to_dec

	lea 	dx, Available_memory
	call 	print
	lea	dx, Endl
	call	print

	mov	al, 30h      ;  amount of extended memory
	out	70h, al
	in	al, 71h
	mov	bl, al
	mov	al, 31h
	out	70h, al
	in	al, 71h
	mov	ah, al
	mov	al, bl

	lea	si, Extended_memory
  add si, 24
	mov dx, 0
	call 	wrd_to_dec

	lea	dx, Extended_memory
	call	print
	lea	dx, Endl
	call 	print

  lea		dx, MCB    ;   MCB blocks
  call 	print
	lea		dx, Endl
	call	print

  mov		ah, 52h  ;getting access to MCB
  int 	21h
  mov 	ax, es:[bx-2]
  mov 	es, ax

    ;type of MCB
tag1:
	  mov 	al, es:[0000h]
    call 	BYTE_TO_HEX
    lea		di,  MCBtype
    add di, 10
    mov 	[di], ax

    lea		dx, MCBtype
    call 	print
    lea		dx, Tab
    call 	print


    mov 	ax, es:[1h]    ; segment address PSP owner of piece of memory
    lea 	di, PSP_address
    add   di, 15
    call 	WRD_TO_HEX

    lea	dx, PSP_address
    call 	print
    lea	dx, Tab
    call 	print

    mov 	ax, es:[0003h] ;
    mov 	cx, 10h
    mul 	cx

    lea 	si, size_s
    add   si, 13
    call 	WRD_TO_DEC
    lea		dx, Size_s
    call 	Print
    lea		dx, Tab
    call 	Print

    ;последние 8 байт
    push 	ds
    push 	es
    pop 	ds

    mov 	dx, 8h
    mov 	di, dx
    mov 	cx, 8h
tag2:
	  cmp		cx,0
	  je		tag3
    mov		dl, byte PTR [di]
    call	Print_symb
    dec 	cx
    inc		di
    jmp		tag2
tag3:
  	pop 	ds
	  lea		dx, Endl
    call 	Print

    cmp 	byte ptr es:[0000h], 5Ah  ; check is the last block or not
    je 		Quit

    mov 	ax, es      ; address of next block
    add 	ax, es:[3h]
    inc 	ax
    mov 	es, ax
    jmp 	tag1

Quit:
    mov ax, 0
    mov 	ah, 4ch ;finish
    int  21h
TESTPC	ENDS
		END  Start


