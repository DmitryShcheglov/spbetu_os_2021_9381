DOSSEG
	.model small
	.stack 100h

.data
pc_type db 'PC type is ', '$'
is_pc db 'PC', 0dh, 0ah, '$'
is_xt db 'PC/XT', 0dh, 0ah, '$'
is_at db 'AT', 0dh, 0ah, '$'
is_ps3 db 'PS2 model 30', 0dh, 0ah, '$'
is_ps5 db 'PS2 model 50 or 60', 0dh, 0ah, '$'
is_ps8 db 'PS2 model 80', 0dh, 0ah, '$'
is_pcjr db 'PCjr', 0dh, 0ah, '$'
is_pc_con db 'PC Convertible', 0dh, 0ah, '$'
is_unknownpc db ' unknown PC type', 0dh, 0ah, '$'
sys_ver db 'System version is  . ', 0dh, 0ah, '$'
oem_num db 'OEM number is   ', 0dh, 0ah, '$'
user_num db 'User number is       ', 0dh, 0ah, '$'

.code
START: JMP BEGIN
;-----------------------------------------------------
TETR_TO_HEX PROC near
	and AL,0Fh
 	cmp AL,09
 	jbe NEXT
 	add AL,07
	NEXT:
	add AL,30h
 	ret
TETR_TO_HEX ENDP

;-------------------------------
BYTE_TO_HEX PROC near
	push CX
 	mov AH,AL
 	call TETR_TO_HEX
	xchg AL,AH
 	mov CL,4
 	shr AL,CL
 	call TETR_TO_HEX 
 	pop CXÿ
 	ret
BYTE_TO_HEX ENDP

;-------------------------------
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

;--------------------------------------------------
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

PRINT_MES PROC near
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
PRINT_MES ENDP

DEFINE_PC_TYPE PROC near
	push ax
	push dx
	push es
	
	mov dx, offset pc_type
	call PRINT_MES

	mov ax, 0f000h
	mov es, ax
	mov al, es:[0fffeh]
	
	cmp al, 0ffh
	je type_pc
	cmp al, 0feh
	je type_xt
	cmp al, 0fbh
	je type_xt
	cmp al, 0fch
	je type_at
	cmp al, 0fah
	je type_30
	cmp al, 0fch
	je type_50
	cmp al, 0f8h
	je type_80
	cmp al, 0fdh
	je type_jr
	cmp al, 0f9h
	je type_conv
	
	;unknown pc type
	call BYTE_TO_HEX
	mov di, offset is_unknownpc
	mov [di], al
	mov [di+1], ah
	mov dx, offset is_unknownpc
	jmp output_type 

	type_pc:
	mov dx, offset is_pc
	jmp output_type
	type_xt:
	mov dx, offset is_xt
	jmp output_type
	type_at:
	mov dx, offset is_at
	jmp output_type
	type_30:
	mov dx, offset is_ps3
	jmp output_type
	type_50:
	mov dx, offset is_ps5
	jmp output_type
	type_80:
	mov dx, offset is_ps8
	jmp output_type
	type_jr:
	mov dx, offset is_pcjr
	jmp output_type
	type_conv:
	mov dx, offset is_pc_con
	jmp output_type


	output_type:
	call PRINT_MES

	pop es
	pop dx
	pop ax
	ret
DEFINE_PC_TYPE ENDP

DEFINE_OS_OEM_USER PROC near
	push ax
	push dx
	push si
	push di
	push bx
	
	mov di, offset sys_ver
	mov ah, 30h
	int 21h

	mov dh, ah
	call BYTE_TO_DEC
	lodsw
	mov [di+18], ah
	mov al, dh
	
	call BYTE_TO_DEC
	lodsw
	mov [di+20], ah

	mov dx, offset sys_ver
	call PRINT_MES

	mov al, bh
	call BYTE_TO_HEX
	mov di, offset oem_num
	mov [di+15], al
	mov [di+16], ah
	mov dx, offset oem_num
	call PRINT_MES

	mov di, offset user_num
	
	mov al, bl
	call BYTE_TO_HEX
	mov [di+15], al
	mov [di+16], ah

	mov ax, cx
	add di, 20
	call WRD_TO_HEX
	
	mov dx, offset user_num
	call PRINT_MES

	pop bx
	pop di
	pop si
	pop dx
	pop ax
	ret
DEFINE_OS_OEM_USER ENDP

;-------------------------------
BEGIN:
	mov ax, @data
	mov ds, ax
	call DEFINE_PC_TYPE
	call DEFINE_OS_OEM_USER
 	xor AL,AL
 	mov AH,4Ch
 	int 21H
END STARTÿ