TESTPC SEGMENT
			ASSUME 	CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
			ORG 	100H
START: 		JMP 	BEGIN

type_of		db		'Type of PC: $'
pc		    db 		'PC',0DH,0ah,'$'
pc_xt 		db 		'PC/XT',0DH,0ah,'$'
at_type		db 		'AT',0DH,0ah,'$'
ps2_m30 	db 		'PS2 model 30',0DH,0ah,'$'
ps2_m80 	db 		'PS2 model 80',0DH,0ah,'$'
pcjr 		db		'PCjr',0DH,0ah,'$'
pc_conv		db 		'PC Convertible',0DH,0ah,'$'
version_pc 	db 		'Version of MS DOS:  .  ',0DH,0ah,'$'
sn_oem 		db 		'Serial number of OEM:   $'
sn_of_user 	db 		'Serial number of user:         $'
at_end 		db 		0DH,0ah,'$'

;ПРОЦЕДУРЫ
;-----------------------------------------------------
TETR_TO_HEX 	PROC 	near
				and 	al,0Fh
				cmp 	al,09
				jbe 	NEXT
				add 	al,07
NEXT:			add 	al,30h
				ret
TETR_TO_HEX 	ENDP
;-------------------------------
BYTE_TO_HEX 	PROC	 near
; байт в al переводится в два символа шестн. числа в AX
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
; в AX - число, di - адрес последнего символа
				push 	bx
				mov 	bh,ah
				call	BYTE_TO_HEX
				mov 	[di],ah
				dec 	di
				mov 	[di],al
				dec 	di
				mov 	al,BH
				call 	BYTE_TO_HEX
				mov 	[di],ah
				dec 	di
				mov 	[di],al
				pop 	bx
				ret
WRD_TO_HEX 		ENDP
;--------------------------------------------------
BYTE_TO_DEC 	PROC 	near
; перевод в 10с/с, SI - адрес поля младшей цифры
				push	cx
				push 	dx
				xor 	ah,ah
				xor		dx,dx
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
				mov		[SI],al
		end_l: 
				pop 	dx
				pop 	cx
				ret
BYTE_TO_DEC		ENDP

print_type 		PROC 	near
				mov 	dx, offset type_of
				
				mov		ah, 09h
				int		21h
				
				mov 	ax, 0F000h
				mov 	es, ax
				mov 	al, es:[0FFFEh]
				
				cmp 	al, 0FFh
				je 		print_pc
				cmp		al, 0FEh
				je 		print_pc_xt
				cmp 	al, 0FBh
				je 		print_pc_xt
				cmp 	al, 0FCh
				je 		print_at
				cmp 	al, 0FAh
				je 		print_ps2_m30
				cmp 	al, 0F8h
				je 		print_ps2_m80
				cmp 	al, 0FDh
				je 		print_pcjr
				cmp 	al, 0F9h
				je 		print_pc_conv

		print_pc:
				mov		dx, offset pc
				jmp 	type_end
    
		print_pc_xt:
				mov 	dx, offset pc_xt 
				jmp 	type_end 

		print_at:
				mov 	dx, offset at_type
				jmp 	type_end 

		print_ps2_m30:
				mov 	dx, offset ps2_m30 
				jmp 	type_end 

		print_ps2_m80:
				mov 	dx, offset ps2_m80 
				jmp 	type_end 

		print_pcjr:
				mov 	dx, offset pcjr 
				jmp 	type_end 

		print_pc_conv:
				mov 	dx, offset pc_conv
				jmp		type_end
				
		type_end:
				mov 	ah,09h
				int 	21h
				ret
				
print_type 		ENDP

print_ver 		PROC 	near
				mov 	ah, 30h
				int 	21h

				push 	ax
				mov 	si, offset version_pc
				add 	si, 19
				call 	BYTE_TO_DEC
				pop 	ax
				mov 	al, ah
				add 	si, 3
				call 	BYTE_TO_DEC
				mov 	dx, offset version_pc
    
				mov 	ah,09h
				int 	21h

				mov 	si, offset sn_oem
				add 	si, 22
				mov 	al, bh
				call 	BYTE_TO_DEC
				mov 	dx, offset sn_oem
    
				mov 	ah,09h
				int 	21h

				mov 	dx, offset at_end
    
				mov 	ah,09h
				int 	21h

				mov 	di, offset sn_of_user
				add 	di, 28
				mov 	ax, cx
				call 	WRD_TO_HEX
				mov 	al, bl
				call 	BYTE_TO_HEX
				sub 	di, 2
				mov 	[di], ax
				mov 	dx, offset sn_of_user
    
				mov 	ah,09h
				int 	21h

				mov 	dx, offset at_end
    
				mov 	ah,09h
				int 	21h

				ret
print_ver 		ENDP

BEGIN:
; . . . . . . . . . . . .
				call 	print_type
				call 	print_ver
; . . . . . . . . . . . .
; Выход в DOS
				xor 	al,al
				mov 	ah,4Ch
				int 	21h
TESTPC 			ENDS
END	START ;конец модуля, START - точка входа