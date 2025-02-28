PCinfo	segment
		assume cs:PCinfo, ds:PCinfo, es:nothing, ss:nothing
	org 	100h
	
start:		
	jmp		begin

	;data
	av_mem 	db 'Amount of available memory:            b$'
	ex_mem 	db 'Size of extended memory:            Kb$'
	mcb 	db 'List of memory control blocks:$'
	typeMCB db 'MCB type: 00h$'
	adrPSP 	db 'PSP adress: 0000h$'
	size_s 	db 'Size:          b$'
    endl	db  13, 10, '$'
    tab		db 	9,'$'
    error	db 'ERROR! Memory can not be allocated!$'

tetr_to_hex proc near
    and 	al, 0Fh
    cmp 	al, 09
    jbe 	next
    add 	al, 07
next:
    add 	al, 30h
    ret
   tetr_to_hex endp

;���� � al ��ॢ������ � ��� ᨬ���� 16-�筮�� �᫠ � ax
byte_to_hex proc near
    push 	cx
    mov 	ah, al
    call 	tetr_to_hex
    xchg 	al, ah
    mov 	cl, 4
    shr 	al, cl
    call 	tetr_to_hex ;� al ����� ���, � ah ������
    pop 	cx
    ret
   byte_to_hex endp

;��ॢ�� � 16 �� 16-� ࠧ�來��� �᫠
;ax - �᫮, di - ���� ��᫥����� ᨬ����
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

;��ॢ�� � 10 ��, si - ���� ���� ����襩 ����
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

;�뢮� ��ப�
print proc near
    push 	ax
    push 	dx
    mov 	ah, 09h
    int 	21h
    pop 	dx
    pop 	ax
    ret
   print endp

;�뢮� ᨬ����
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

;������⢮ ����㯭�� �����    
	mov 	ah, 4Ah
	mov 	bx, 0ffffh
	int 	21h
    
	xor		dx, dx
	mov 	ax, bx
	mov 	cx, 10h
	mul 	cx
	
	mov  	si, offset av_mem+37
	call 	wrd_to_dec
    
	mov 	dx, offset av_mem
	call 	print
	mov		dx, offset endl
	call	print
	
;�᢮�������� �����
    mov 	ax,offset SegEnd
    mov 	bx, 10h
    xor 	dx, dx
    div 	bx
    inc 	ax
    mov 	bx, ax
    mov 	al, 0
    mov 	ah, 4Ah
    int 	21h	
    
;����� �����
	xor		ax, ax
	mov		ah, 48h	
	mov		bx, 1000h
	int		21h
	jnc		mem_ok
	mov		dx, offset error
	call	print
	mov		dx,	offset endl
	call	print
mem_ok:	
    	
;ࠧ��� ���७��� �����    
	mov		al, 30h
	out		70h, al
	in		al, 71h
	mov		bl, al ;����訩 ����
	mov		al, 31h
	out		70h, al
	in		al, 71h ;���訩 ����
	mov		ah, al
	mov		al, bl

	mov	 	si, offset ex_mem+34
	xor 	dx, dx
	call 	wrd_to_dec
	
	mov		dx, offset ex_mem
	call	print
	mov		dx, offset endl
	call 	print

;楯�窠 ������ �ࠢ����� �������    
    mov		dx, offset mcb
    call 	print
	mov		dx, offset endl
	call	print
    
    mov		ah, 52h
    int 	21h
    mov 	ax, es:[bx-2]
    mov 	es, ax
	
    ;⨯ MCB
tag1:
	mov 	al, es:[0000h]
    call 	byte_to_hex
    mov		di, offset typeMCB+10
    mov 	[di], ax
      
    mov		dx, offset typeMCB
    call 	print
    mov		dx, offset tab
    call 	print
     
    ;ᥣ����� ���� PSP �������� ���⪠ �����    
    mov 	ax, es:[0001h]
    mov 	di, offset adrPSP+15
    call 	wrd_to_hex
    
    mov		dx, offset adrPSP
    call 	print
    mov		dx, offset tab
    call 	print
    
    ;ࠧ��� ���⪠ � ��ࠣ���
    mov 	ax, es:[0003h]
    mov 	cx, 10h 
    mul 	cx
	
	mov		si, offset size_s+13
    call 	wrd_to_dec
    mov		dx, offset size_s
    call 	print  
    mov		dx, offset tab
    call 	print
	
    ;��᫥���� 8 ����
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
    call	print_symb
    dec 	cx
    inc		di
    jmp		tag2
tag3:    
	pop 	ds
	mov		dx, offset endl
    call 	print
    
    ;�஢�ઠ, ��᫥���� ���� ��� ���
    cmp 	byte ptr es:[0000h], 5ah
    je 		quit
    
    ;���� ᫥���饣� �����
    mov 	ax, es
    add 	ax, es:[0003h]
    inc 	ax
    mov 	es, ax
    jmp 	tag1
         
quit:          
  
    xor 	ax, ax
    mov 	ah, 4ch
    int 	21h
SegEnd:    
PCinfo	ENDS
		END    START