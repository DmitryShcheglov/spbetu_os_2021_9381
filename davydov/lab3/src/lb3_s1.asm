MAIN	SEGMENT
		ASSUME CS:MAIN, DS:MAIN, ES:nothing, SS:nothing
	org		100h
	
start:		
	jmp		begin

	;data
	availableMemory	DB	'Amount of available memory:            b$'
	extendedMemory	DB	'Size of extended memory:            Kb$'
	mcb		DB	'List of memory control blocks:$'
	typeMCB	DB	'MCB type: 00h$'
	adressPSP	DB	'PSP adress: 0000h$'
	size_s	DB	'Size:          b$'
    endl	DB	13, 10, '$'
    tab		DB	9, '$'

tetr_to_hex proc near
    and		al, 0Fh
    cmp		al, 09
    jbe 	next
    add 	al, 07
next:
    add 	al, 30h
    ret
	tetr_to_hex endp

;Байт из al -> два символа 16-ричного числа в ax
byte_to_hex proc near
    push 	cx
    mov 	ah, al
    call 	tetr_to_hex
    xchg 	al, ah
    mov 	cl, 4
    shr 	al, cl
    call 	tetr_to_hex ; старшая цифра в al , младшая в ah
    pop 	cx
    ret
	byte_to_hex endp

;Перевод 16-ти разрядного числа в 16 сс.
;число в ах, последний символ в di
wrd_to_hex proc near
    push 	bx
    mov 	bh, ah
    call 	byte_to_hex
    mov 	[di], ah
    dec 	di
    mov 	[di], al
    dec 	di
    mov 	al, bh
    call 	byte_to_hex
    mov 	[di], ah
    dec 	di
    mov 	[di], al
    pop 	bx
    ret
	wrd_to_hex endp

;Перевод в 10 сс, поле младшей цифры в si
byte_to_dec proc near
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
	byte_to_dec endp
   
wrd_to_dec proc near
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
	wrd_to_dec endp

;вывод строки
print proc near
    push 	ax
    push 	dx
    mov 	ah, 09h
    int 	21h
    pop 	dx
    pop 	ax
    ret
	print endp

;вывод символа
print_symb proc near
	push	ax
	push	dx
	mov		ah, 02h
	int		21h
	pop		dx
	pop		ax
	ret
	print_symb endp
   
begin:
;количество доступной памяти    
	mov 	ah, 4Ah
	mov 	bx, 0ffffh
	int 	21h
    
	xor	dx, dx
	mov 	ax, bx
	mov 	cx, 10h
	mul 	cx
	
	mov  	si, offset availableMemory+37
	call 	wrd_to_dec
    
	mov 	dx, offset availableMemory
	call 	print
	mov	dx, offset endl
	call	print
	
;размер расширенной памяти    
	mov	al, 30h
	out	70h, al
	in	al, 71h
	mov	bl, al ;младший байт
	mov	al, 31h
	out	70h, al
	in	al, 71h ;старший байт
	mov	ah, al
	mov	al, bl

	mov	si, offset extendedMemory+34
	xor 	dx, dx
	call 	wrd_to_dec
	
	mov	dx, offset extendedMemory
	call	print
	mov	dx, offset endl
	call 	print

;цепочка блоков управления памятью    
    mov		dx, offset mcb
    call 	print
	mov		dx, offset endl
	call	print
    
    mov		ah, 52h
    int 	21h
    mov 	ax, ES:[bx-2]
    mov 	ES, ax
    ;тип MCB
tag1:
	mov 	al, ES:[0000h]
    call 	byte_to_hex
    mov		di, offset typeMCB+10
    mov 	[di], ax
      
    mov		dx, offset typeMCB
    call 	print
    mov		dx, offset tab
    call 	print
     
    ;сегментный адрес PSP владельца участка памяти    
    mov 	ax, ES:[0001h]
    mov 	di, offset adressPSP+15
    call 	wrd_to_hex
    
    mov		dx, offset adressPSP
    call 	print
    mov		dx, offset tab
    call 	print
    
    ;размер участка в параграфах
    mov 	ax, ES:[0003h]
    mov 	cx, 10h 
    mul 	cx
	
	mov		si, offset size_s+13
    call 	wrd_to_dec
    mov		dx, offset size_s
    call 	print  
    mov		dx, offset tab
    call 	print
	
    ;последние 8 байт
    push 	DS
    push 	ES
    pop 	DS
    
    mov 	dx, 08h
    mov 	di, dx
    mov 	cx, 8
	
tag2:
	cmp		cx,0
	je		tag3
    mov		dl, byte PTR [di]
    call	print_symb
    dec 	cx
    inc		di
    jmp		tag2
	
tag3:    
	pop 	DS
	mov		dx, offset endl
    call 	print
    
    ;проверка на последний блок
    cmp 	byte ptr ES:[0000h], 5ah
    je 		quit
    
    ;адрес следующего блока
    mov 	ax, ES
    add 	ax, ES:[0003h]
    inc 	ax
    mov 	ES, ax
    jmp 	tag1
	
quit:         
  
    xor 	ax, ax
    mov 	ah, 4ch
    int 	21h
MAIN	ENDS
		END    START