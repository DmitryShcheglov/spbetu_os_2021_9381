LAB	segment
		assume cs:LAB, ds:LAB, es:NOTHING, ss:NOTHING
	org 	100h
	
START:	jmp		BEGIN
	availableMemory 	db 'Amount of available memory:            b$'
	extendedMemory 	db 'Size of extended memory:            Kb$'
	mcbNums 	db 'List of memory control blocks:$'
	mcbType db 'MCB type: 00h$'
	pspAdress 	db 'PSP adress: 0000h$'
	sizeS 	db 'Size:          b$'
    endLine	db  13, 10, '$'
    tab		db 	9,'$'
    memoryFail	db 'ERROR! Memory can not be allocated!$'

TETR_TO_HEX proc near
    and 	al, 0Fh
    cmp 	al, 09
    jbe 	next
    add 	al, 07
next:
    add 	al, 30h
    ret
   TETR_TO_HEX endp

;Байт из al -> два символа 16-ричного числа из ax
BYTE_TO_HEX proc near
    push 	cx
    mov 	ah, al
    call 	TETR_TO_HEX
    xchg 	al, ah
    mov 	cl, 4
    shr 	al, cl
    call 	TETR_TO_HEX ; старшая цифра в al, младшая в ah
    pop 	cx
    ret
   BYTE_TO_HEX endp

;Перевод 16-ти разрядного числа в 16 сс.
;в ax - число, в di - адрес последнего символа
WRD_TO_HEX proc near
    push 	bx
    mov 	bh, ah
    call 	BYTE_TO_HEX
    mov 	[di], ah
    dec 	di
    mov 	[di], al
    dec 	di
    mov 	al, bh
    call 	BYTE_TO_HEX
    mov 	[di], ah
    dec 	di
    mov 	[di], al
    pop 	bx
    ret
   WRD_TO_HEX endp

;Перевод в 10 сс,в si - поле младшей цифры
BYTE_TO_DEC proc near
    push 	cx
    push 	dx
    xor 	ah, ah
    xor 	dx, dx
    mov 	cx, 10
loop_bd:
    div 	cx
    or 		dl, 30h
    mov 	[si], dl
    dec 	si
    xor 	dx, dx
    cmp 	ax, 10
    jae 	loop_bd
    cmp 	al, 00h
    je 		end_l
    or 		al, 30h
    mov 	[si], al
end_l:
    pop 	dx
    pop 	cx
    ret
   BYTE_TO_DEC endp
   
WRD_TO_DEC proc near
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
PRINT_STRING proc near
    push 	ax
    push 	dx
    mov 	ah, 09h
    int 	21h
    pop 	dx
    pop 	ax
    ret
   PRINT_STRING endp

;вывод символа
PRINT_SYMBOL proc near
	push	ax
	push	dx
	mov		ah, 02h
	int		21h
	pop		dx
	pop		ax
	ret
   PRINT_SYMBOL endp
   
BEGIN:

;количество доступной памяти    
	mov 	ah, 4Ah
	mov 	bx, 0ffffh
	int 	21h
    
	xor		dx, dx
	mov 	ax, bx
	mov 	cx, 10h
	mul 	cx
	
	mov  	si, offset availableMemory+37
	call 	WRD_TO_DEC
    
	mov 	dx, offset availableMemory
	call 	PRINT_STRING
	mov		dx, offset endLine
	call	PRINT_STRING
	
    
;запрос памяти
	xor		ax, ax
	mov		ah, 48h	
	mov		bx, 1000h
	int		21h
	jnc		mem_ok
	mov		dx, offset memoryFail
	call	PRINT_STRING
	mov		dx,	offset endLine
	call	PRINT_STRING
mem_ok:	

;освобождение памяти
    mov 	ax,offset SegEnd
    mov 	bx, 10h
    xor 	dx, dx
    div 	bx
    inc 	ax
    mov 	bx, ax
    mov 	al, 0
    mov 	ah, 4Ah
    int 	21h	
    	
;размер расширенной памяти    
	mov		al, 30h
	out		70h, al
	in		al, 71h
	mov		bl, al ;младший байт
	mov		al, 31h
	out		70h, al
	in		al, 71h ;старший байт
	mov		ah, al
	mov		al, bl

	mov	 	si, offset extendedMemory+34
	xor 	dx, dx
	call 	WRD_TO_DEC
	
	mov		dx, offset extendedMemory
	call	PRINT_STRING
	mov		dx, offset endLine
	call 	PRINT_STRING

;цепочка блоков управления памятью    
    mov		dx, offset mcbNums
    call 	PRINT_STRING
	mov		dx, offset endLine
	call	PRINT_STRING
    
    mov		ah, 52h
    int 	21h
    mov 	ax, es:[bx-2]
    mov 	es, ax
	
    ;тип MCB
tag1:
	mov 	al, es:[0000h]
    call 	BYTE_TO_HEX
    mov		di, offset mcbType+10
    mov 	[di], ax
      
    mov		dx, offset mcbType
    call 	PRINT_STRING
    mov		dx, offset tab
    call 	PRINT_STRING
     
    ;сегментный адрес PSP владельца участка памяти    
    mov 	ax, es:[0001h]
    mov 	di, offset pspAdress+15
    call 	WRD_TO_HEX
    
    mov		dx, offset pspAdress
    call 	PRINT_STRING
    mov		dx, offset tab
    call 	PRINT_STRING
    
    ;размер участка в параграфах
    mov 	ax, es:[0003h]
    mov 	cx, 10h 
    mul 	cx
	
	mov		si, offset sizeS+13
    call 	WRD_TO_DEC
    mov		dx, offset sizeS
    call 	PRINT_STRING  
    mov		dx, offset tab
    call 	PRINT_STRING
	
    ;последние 8 байт
    push 	ds
    push 	es
    pop 	ds
    
    mov 	dx, 08h
    mov 	di, dx
    mov 	cx, 8
tag2:
	cmp		cx,0
	je		tag3
    mov		dl, byte PTR [di]
    call	PRINT_SYMBOL
    dec 	cx
    inc		di
    jmp		tag2
tag3:    
	pop 	ds
	mov		dx, offset endLine
    call 	PRINT_STRING
    
    ;проверка на последний блок
    cmp 	byte ptr es:[0000h], 5ah
    je 		endProgramm
    
    ;адрес следующего блока
    mov 	ax, es
    add 	ax, es:[0003h]
    inc 	ax
    mov 	es, ax
    jmp 	tag1
         
endProgramm:          
  
    xor 	ax, ax
    mov 	ah, 4ch
    int 	21h
SegEnd:    
LAB	ENDS
		END    START