TESTPC 				SEGMENT
					ASSUME 	CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
					ORG 	100H
START: 				JMP 	BEGIN
; ДАННЫЕ 
n 					db 		0dh, 0ah, '$'
area_size 			db 		"size:        ", '$'
SC_SD 				db 		"SC/SD: ", '$'
address 			db		"address:      ", '$'
PSP_address 		db 		"PSP address:      ", '$'
extended_mem_size 	db 		"extended memory size:        bytes", 0dh, 0ah, '$'
available_mem_size 	db 		"available memory size:        bytes", 0dh, 0ah, '$' 
MCB_number 			db 		"MCB #", '$'
dec_number 			db 		"   ", '$'
mem_accept 			db 		"New memory has been added!", 0dh, 0ah, '$'
mem_fail 			db 		"New memory hasn't been added!", 0dh, 0ah,'$'

;ПРОЦЕДУРЫ
;-----------------------------------------------------
TETR_TO_HEX 		PROC 	near
					and 	al,0Fh
					cmp 	al,09
					jbe 	NEXT
					add 	al,07
			NEXT: 	add 	al,30h
					ret
TETR_TO_HEX 		ENDP
;-------------------------------
BYTE_TO_HEX 		PROC 	near
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
BYTE_TO_HEX 		ENDP
;-------------------------------
WRD_TO_HEX 			PROC 	near
;перевод в 16 с/с 16-ти разрядного числа
; в ax - число, di - адрес последнего символа
					push 	bx
					mov 	bh,ah
					call 	BYTE_TO_HEX
					mov 	[di],ah
					dec 	di
					mov 	[di],al
					dec 	di
					mov 	al,bh
					call 	BYTE_TO_HEX
					mov 	[di],ah
					dec 	di
					mov 	[di],al
					pop 	bx
					ret
WRD_TO_HEX 			ENDP
;--------------------------------------------------
BYTE_TO_DEC 		PROC 	near
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
BYTE_TO_DEC 		ENDP
;-------------------------------
; КОД
para_to_byte 		PROC
					push	ax
					push	bx
					push 	cx
					push 	dx
					push 	si
   
					mov 	bx, 10h
					mul 	bx
					mov 	bx, 0ah
					xor 	cx, cx

			div_loop:
					div 	bx
					push 	dx
					inc 	cx
					sub 	dx, dx
					cmp 	ax, 0h
					jnz 	div_loop
   
			print_sym:
					pop 	dx
					add 	dl, 30h
					mov 	[si], dl
					inc 	si
					loop 	print_sym
   
					pop 	si
					pop 	dx
					pop 	cx
					pop 	bx
					pop 	ax
					ret
para_to_byte 		ENDP

print_n 			PROC 	near
					push 	ax
					push 	dx

					mov 	dx, offset n
					mov 	ah, 9h
					int 	21h

					pop 	dx
					pop 	ax
					ret
print_n 			ENDP

print_av_mem_size 	PROC 	near
					mov 	ah, 4ah
					mov 	bx, 0ffffh
					int 	21h
					mov 	ax, bx
					mov 	si, offset available_mem_size
					add 	si, 23
					call 	para_to_byte    
					mov 	dx, offset available_mem_size
    
					mov 	ah, 09h
					int 	21h
	
					ret
print_av_mem_size 	ENDP

print_ext_mem_size 	PROC 	near
					mov 	al,30h ; запись адреса ячейки CMOS
					out 	70h,al
					in 		al,71h ; чтение младшего байта
					mov 	bl,al ; размера расширенной памяти
					mov 	al,31h ; запись адреса ячейки CMOS
					out 	70h,al
					in 		al,71h ; чтение старшего байта
    ; размера расширенной памяти
					mov 	ah, al
					mov 	si, offset extended_mem_size
					add 	si, 22
					call 	para_to_byte
					mov 	dx, offset extended_mem_size
    
					mov 	ah, 09h
					int 	21h
	
					ret
print_ext_mem_size	ENDP

print_mcb 			PROC 	near
					push 	ax
					push 	dx
					push 	si
					push 	di
					push 	cx

					mov 	ax, es;MCB
					mov 	di, offset address
					add 	di, 12
					call 	WRD_TO_HEX
					mov 	dx, offset address

					mov 	ah, 09h
					int 	21h

					mov 	ax, es:[1] ;PSP
					mov 	di, offset PSP_address
					add 	di, 16
					call 	WRD_TO_HEX
					mov 	dx, offset PSP_address

					mov 	ah, 09h
					int 	21h

					mov 	ax, es:[3] ;size of para
					mov 	si, offset area_size
					add 	si, 6
					call 	para_to_byte
					mov 	dx, offset area_size
    
					mov 	ah, 09h
					int 	21h	
	
					mov 	bx, 8 ;SC SD
					mov 	dx, offset SC_SD
    
					mov 	ah, 09h
					int 	21h	
	
					mov 	cx, 7
			print_sc_sd_loop:
					mov 	dl, es:[bx]
					mov 	ah, 02h
					int 	21h
					inc 	bx
					loop 	print_sc_sd_loop

					pop 	cx
					pop 	di
					pop 	si
					pop 	dx
					pop 	ax
					ret
print_mcb 			ENDP

offset_dec 			PROC 	near
			offset_dec_loop:
					cmp 	byte ptr [si], ' '
					jne 	end_offset_dec
					inc 	si
					jmp 	offset_dec_loop
			end_offset_dec:
					ret
offset_dec 			ENDP

print_mcb_list 		PROC 	near
					push 	ax
					push 	bx
					push 	es
					push 	dx

					mov 	ah, 52h
					int 	21h
					mov 	ax, es:[bx-2]
					mov 	es, ax
					mov 	cl, 1
			print_list:
					mov 	dx, offset MCB_number
        
					mov 	ah, 09h
					int 	21h	
		
					mov 	al, cl
					mov 	si, offset dec_number
					add 	si, 2
					call 	BYTE_TO_DEC
					call 	offset_dec
					mov 	dx, si
     
					mov 	ah, 09h
					int 	21h
        
					mov 	dl, ':'
					mov 	ah, 02h
					int 	21h
					mov 	dl, ' '
					mov 	ah, 02h
					int 	21h
					call 	print_mcb 
					call 	print_n
					mov 	al, es:[0]
					cmp 	al, 5ah
					je 		end_mcb_list

					mov 	bx, es:[3]
					mov 	ax, es
					add 	ax, bx
					inc 	ax
					mov 	es, ax
					inc 	cl
					jmp 	print_list

			end_mcb_list:
					pop 	dx
					pop 	es
					pop 	bx
					pop 	ax
					ret
print_mcb_list 		ENDP

del_free_memory 	PROC 	near
					push 	ax
					push 	bx
					push 	cx
					push 	dx
    
					lea 	ax, final_end
					mov 	bx,10h
					sub 	dx,dx
					div 	bx
					inc 	ax
					mov 	bx,ax
					mov 	al,0
					mov 	ah,4Ah
					int 	21h
    
					pop 	dx
					pop 	cx
					pop 	bx
					pop 	ax
					ret
del_free_memory 	ENDP

memory_request 		PROC 	near
					push 	ax
					push	bx
					push 	dx
   
					mov 	bx, 1000h
					mov 	ah, 48h
					int 	21h
					jc 		mem_failed
					jmp 	mem_accepted
   
			mem_failed:
					mov 	dx, offset mem_fail
					mov 	ah, 09h
					int 	21h
					jmp 	end_memory_request

			mem_accepted:
					mov 	dx, offset mem_accept
					mov 	ah, 09h
					int 	21h

end_memory_request:
					pop 	dx
					pop 	bx
					pop 	ax
					ret
memory_request 		ENDP
BEGIN:
; . . . . . . . . . . . .
					call 	print_av_mem_size
					call 	print_ext_mem_size
					call 	memory_request					
					call	del_free_memory					
					call 	print_mcb_list
; . . . . . . . . . . . .
; Выход в DOS
					xor 	al,al
					mov 	ah,4Ch
					int 	21H
			final_end:
TESTPC 				ENDS
					END 	START