DOSSEG
.model small
.stack 100h

;ДАННЫЕ
.data
pc_type_string DB 'PC type - ', '$'
pc_type_1 DB 'PC', 0DH, 0AH, '$'
pc_type_2 DB 'PC/XT', 0DH, 0AH, '$'
pc_type_3 DB 'AT', 0DH, 0AH, '$'
pc_type_4 DB 'PS2 model 30', 0DH, 0AH, '$'
pc_type_5 DB 'PS2 model 50 or 60', 0DH, 0AH, '$'
pc_type_6 DB 'PS2 model 80', 0DH, 0AH, '$'
pc_type_7 DB 'PCjr', 0DH, 0AH, '$'
pc_type_8 DB 'PC Convertible', 0DH, 0AH, '$'
unknown_pc_type DB '     error. Unknown', 0DH, 0AH ,'$'
System_version DB 'System version:  .  ',0DH, 0AH, '$'
OEM DB 'OEM:   ', 0DH, 0AH, '$'
user_serial_number DB 'Serial user number:       ',0DH, 0AH, '$'


.code
START:
	jmp BEGIN
;Представление 4 бита регистра al в виде цифры 16ой с.с. и представление её в символьном виде. 
TETR_TO_HEX PROC near
	and AL,0Fh
	cmp AL,09
	jbe NEXT
	add AL,07
NEXT: 
	add AL,30h ; результат в al
	ret
TETR_TO_HEX ENDP

;Представление al как два числа в 16-ой с.с. и перемещение их в ax
BYTE_TO_HEX PROC near
	push CX
	mov AH,AL
	call TETR_TO_HEX
	xchg AL,AH
	mov CL,4
	shr AL,CL
	call TETR_TO_HEX ;в AL старшая цифра
	pop CX ;в AH 	младшая
	ret
BYTE_TO_HEX ENDP

; перевод в 16 с/c 16-ти разрядного числа
; в AX - число, DI - адрес последнего символа
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

; перевод в 10 с/c. SI - адрес поля младшей цифры
BYTE_TO_DEC PROC near
	push CX
	push DX
	xor AH,AH
	xor DX,DX
	mov CX,10
loop_bd: div CX
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

WRITE PROC NEAR
	push ax
	mov   AH, 9
    int   21h  ; Вызов функции DOS по прерыванию
	pop ax
    ret
WRITE ENDP

GET_PC_TYPE PROC NEAR
	push ax
	push dx
	push es
	mov ax, 0F000h
	mov es, ax
	mov al, es:[0FFFEh]
	mov dx, offset pc_type_string
	call WRITE

	cmp al, 0FFh
	je pc_type_1_case
	cmp al, 0FEh
	je pc_type_2_case
	cmp al, 0FBh
	je pc_type_2_case
	cmp al, 0FCh
	je pc_type_3_case
	cmp al, 0FAh
	je pc_type_4_case
	cmp al, 0FCh
	je pc_type_5_case
	cmp al, 0F8h
	je pc_type_6_case
	cmp al, 0FDh
	je pc_type_7_case
	cmp al, 0F9h
	je pc_type_8_case
	jmp unknown_pc_type_case
	
pc_type_1_case:
	mov dx, offset pc_type_1
	jmp final_step
pc_type_2_case:
	mov dx, offset pc_type_2
	jmp final_step
pc_type_3_case:
	mov dx, offset pc_type_3
	jmp final_step
pc_type_4_case:
	mov dx, offset pc_type_4
	jmp final_step
pc_type_5_case:
	mov dx, offset pc_type_5
	jmp final_step
pc_type_6_case:
	mov dx, offset pc_type_6
	jmp final_step
pc_type_7_case:
	mov dx, offset pc_type_7
	jmp final_step
pc_type_8_case:
	mov dx, offset pc_type_8
	jmp final_step
	
unknown_pc_type_case:
	mov dx, offset unknown_pc_type
	push ax
	call BYTE_TO_HEX
	mov si, dx
	mov [si], al
	inc si
	mov [si], ah
	pop ax
final_step:
	call write
end_of_proc:
	pop es
	pop dx
	pop ax
	ret
GET_PC_TYPE ENDP

GET_VERSRION PROC NEAR
	push ax
	push dx
	MOV AH,30h
	INT 21
	
;Сначала надо обработать al - xx, а потом ah - yy и записать в System_version
		push ax
		push si
		lea si, System_version
		add si, 16
		call BYTE_TO_DEC
		add si, 3
		mov al, ah
		call BYTE_TO_DEC
		pop si
		pop ax
;OEM
	mov al, bh
	lea si, OEM
	add si, 7
	call BYTE_TO_DEC
	
;get_user_serial_number
	mov al, bl
	call BYTE_TO_HEX
	lea di, user_serial_number
	add di, 20
	mov [di], ax
	mov ax, cx
	lea di, user_serial_number
	add di, 25
	call WRD_TO_HEX

version_:
	mov dx, offset System_version
	call WRITE
get_OEM:
	mov dx, offset OEM
	call write
get_user_serial_number:
	mov dx, offset user_serial_number
	call write
end_of_proc_2:
	pop dx
	pop ax
	ret
GET_VERSRION ENDP

BEGIN:
	mov ax, @data
	mov ds, ax
	call GET_PC_TYPE
	call GET_VERSRION
	;выход в ДОС
	xor AL,AL
	mov AH,4Ch
	int 21H
END START
; КОНЕЦ МОДУЛЯ