TESTPC 	SEGMENT
			
		ASSUME 	CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
		ORG 	100H
START: 	JMP 	BEGIN
; ДАННЫЕ 
seg_ad_un_mem 	db		'Segment address of the unvailible memory:     h',0DH,0ah,'$'
seg_ad_env 		db 		'Segment address of the environment:     h',0DH,0ah,'$'
tail_of_com_str db 		'Tail of the command string:',0DH,0ah,'$'
no_tail 		db 		'Tail is empty',0DH,0ah,'$'
new_str 		db 		0DH,0ah,'$'
tail 			db 		'                                                        ',0DH,0ah,'$'
cont_env_area 	db 		'Content of the environment area: ',0DH,0ah,'$'
path 			db 		'Path of the loaded module:',0DH,0ah,'$'
;ПРОЦЕДУРЫ
;-----------------------------------------------------
TETR_TO_HEX 	PROC 	near
				and 	al,0Fh
				cmp 	al,09
				jbe 	NEXT
				add 	al,07
		NEXT: 	add 	al,30h
				ret
TETR_TO_HEX 	ENDP
;-------------------------------
BYTE_TO_HEX 	PROC 	near
; байт в al переводится в два символа шестн. числа в ax
				push 	cx
				mov 	ah,al
				call 	TETR_TO_HEX
				xchg 	al,ah
				mov 	cl,4
				shr 	al,cl
				call 	TETR_TO_HEX ;в al старшая цифра
				pop 	cx ;в ah младшая
				ret
BYTE_TO_HEX 	ENDP
;-------------------------------
WRD_TO_HEX 		PROC 	near
;перевод в 16 с/с 16-ти разрядного числа
; в ax - число, di - адрес последнего символа
				push 	bx
				mov 	bh,ah
				call 	BYTE_TO_HEX
				mov 	[di],ah
				dec 	di
				mov 	[di],al
				dec 	di
				mov	 	al,bh
				call 	BYTE_TO_HEX
				mov	 	[di],ah
				dec 	di
				mov 	[di],al
				pop 	bx
				ret
WRD_TO_HEX 		ENDP
;--------------------------------------------------
BYTE_TO_DEC 	PROC 	near
; перевод в 10с/с, si - адрес поля младшей цифры
				push 	cx
				push 	dx
				xor 	ah,ah
				xor 	dx,dx
				mov 	cx,10
		loop_bd: 
				div 	cx
				or 		dl,30h
				mov 	[si],dl
				dec 	si
				xor 	dx,dx
				cmp 	ax,10
				jae 	loop_bd
				cmp 	al,00h
				je 		end_l
				or 		al,30h
				mov 	[si],al
		end_l: 
				pop 	dx
				pop 	cx
				ret
BYTE_TO_DEC 	ENDP
;-------------------------------
; КОД

print_inf 		PROC 	near
		seg_memory:
				mov 	ax, ds:[02h]
				mov 	di, offset seg_ad_un_mem
				add 	di, 45
				call 	WRD_TO_HEX
				mov 	dx, offset seg_ad_un_mem
    
				mov 	ah, 09h
				int 	21h
				

		seg_environment:
				mov 	ax, ds:[2Ch]
				mov 	di, offset seg_ad_env
				add 	di, 39
				call 	WRD_TO_HEX
				mov 	dx, offset seg_ad_env
    
				mov 	ah, 09h
				int 	21h
				

		tail_com:
				mov 	dx, offset tail_of_com_str
    
				mov 	ah, 09h
				int 	21h
				
    
				sub 	cx, cx
				sub 	ax, ax
				sub 	di, di
				mov 	cl, ds:[80h]
				mov 	si, offset tail
				cmp 	cl, 0
				je 		if_zero
		string_loop:;cx = cx - 1
				mov 	al, ds:[81h + di]
				inc 	di
				mov 	[si], al
				inc 	si
		loop string_loop
				mov 	dx, offset tail
    
				mov 	ah, 09h
				int 	21h
				
				jmp 	content_of_environment

		if_zero:
				mov		dx, offset no_tail
    
				mov 	ah, 09h
				int 	21h
				
				jmp 	content_of_environment

		content_of_environment:
				mov		dx, offset cont_env_area

				mov 	ah, 09h
				int 	21h

				sub 	di, di
				mov 	bx, 2Ch
				mov 	ds, [bx]
		loop_env_string:
				cmp 	byte ptr [di], 00h ;проверка на конец строки
				je 		next_string
				mov 	dl, [di];вывод
				mov 	ah, 02h
				int 	21h
				jmp 	check_path
		next_string:
				push 	ds
				mov 	cx, cs
				mov 	ds, cx
				mov 	dx, offset new_str ;перенос на новую строку
	
				mov 	ah, 09h
				int 	21h
	
				pop 	ds
		check_path:
				inc 	di
				cmp 	word ptr [di], 0001h ;начался путь
				je 		print_path
				jmp 	loop_env_string
		print_path:
				push 	ds
				mov 	ax, cs
				mov 	ds, ax
				mov 	dx, offset path

				mov 	ah, 09h
				int 	21h

				pop 	ds
				add 	di, 2 ;на начало пути
		loop_path:
				cmp 	byte ptr [di], 00h;проверка на конец пути
				je 		to_end
				mov 	dl, [di]
				mov 	ah, 02h
				int 	21h
				inc 	di
				jmp 	loop_path
		to_end:
				ret
print_inf 		ENDP

BEGIN:
; . . . . . . . . . . . .
				call 	print_inf
; . . . . . . . . . . . .
; Выход в DOS
				mov		ah, 01h
				int		21h
				mov		ah,4Ch
				int 	21H
TESTPC 			ENDS
				END 	START