LAB2 SEGMENT
	ASSUME CS: LAB2, DS:LAB2, ES: NOTHING, SS:NOTHING
	ORG 100H
START: 
	JMP BEGIN

;ДАННЫЕ

STRING db 'Значение регистра AX =     ', 0Dh, 0AH, '$'

UNREACH_MEM_ADDRESS db 'Segment address of unreacheble memory:     h', 0Dh, 0Ah, '$'
SEGMENT_ADDRESS_ENV db 'Segment address of enviroment:     h', 0Dh, 0Ah, '$'
EMPTY_COM_TAIL db 'Tail of command string is empty!', 0Dh, 0Ah, '$'
COM_TAIL db 'Tail of command string: ', 0Dh, 0Ah, '$'
TAIL_BYTES db 127 dup (' '), 0Dh, 0Ah, '$' 
CONTENT_STRING db 'Content of environment:', 0Dh, 0Ah, '$' 

PC_WAY db 127 dup (' '), 0Dh, 0Ah, '$' 

;Процедуры
;==============================================
TETR_TO_HEX PROC near
	and AL, 0Fh
	cmp AL, 09
	jbe NEXT
	add AL, 07
NEXT:
	add AL, 30h
	ret	
TETR_TO_HEX ENDP
;==============================================
BYTE_TO_HEX PROC near
; байт в AL переводится в два символа шестн. числа в AX
	push CX
	mov AH, AL
	call TETR_TO_HEX
	xchg AL, AH
	mov CL, 4
	shr AL, CL
	call TETR_TO_HEX; в AL старшая цифра
	pop CX 			; в AH младшая
	ret
BYTE_TO_HEX ENDP
;==============================================
WRD_TO_HEX PROC near
; перевод в 16 c/c 16-ти разрядного числа
; в AX - число, DI - адрс последнего символа
	push BX
	mov BH, AH
	call BYTE_TO_HEX
	mov [DI], AH
	dec DI
	mov [DI], AL
	dec DI
	mov AL, BH
	call BYTE_TO_HEX
	mov [DI], AH
	dec DI
	mov [DI], AL
	pop BX
	ret	
WRD_TO_HEX ENDP
;==============================================
BYTE_TO_DEC PROC near
; перевод в 10c/c, SI - адрес поля младшей цифры
	push CX
	push DX
	xor AH, AH
	xor DX, DX
	mov CX, 10
loop_bd:
	div CX
	or DL, 30h
	mov [SI], DL
	dec SI
	xor DX, DX
	cmp AX, 10
	jae loop_bd
	cmp AL, 00h
	je end_l
	or AL, 30h
	mov [SI], AL
end_l:
	pop DX
	pop CX
	ret	
BYTE_TO_DEC ENDP
;==============================================
OUTPUTTING_STRING_TO_CONSOLE PROC near
	mov AH,09h
	int 21h
	ret
OUTPUTTING_STRING_TO_CONSOLE ENDP
;==============================================
UNREACHABLE_PSP_MEM PROC near
	mov BX, DS:[002h]
	MOV AX, BX
	mov DI, offset UNREACH_MEM_ADDRESS
	add DI, 42
	call WRD_TO_HEX
	mov DX, offset UNREACH_MEM_ADDRESS
	call OUTPUTTING_STRING_TO_CONSOLE
	ret
UNREACHABLE_PSP_MEM ENDP
;==============================================
SEGMENT_ADDRESS_ENVIRONEMNT PROC near
	mov BX, DS:[2Ch]
	MOV AX, BX
	mov DI, offset SEGMENT_ADDRESS_ENV
	add DI, 34
	call WRD_TO_HEX
	mov DX, offset SEGMENT_ADDRESS_ENV
	call OUTPUTTING_STRING_TO_CONSOLE
	ret
SEGMENT_ADDRESS_ENVIRONEMNT ENDP
;==============================================
COMMAND_TAIL PROC near
    xor CX, CX
    mov CL, DS:[80h]
    cmp CL, 000h
    je empty_tail
    mov DX, offset COM_TAIL
    call OUTPUTTING_STRING_TO_CONSOLE
    mov SI, offset TAIL_BYTES
    
    xor di, di
	xor ax, ax
reading_tail:
    mov AL, DS:[81h+DI]
    inc DI
    mov [SI], AL
    inc SI
    loop reading_tail
    mov DX, offset TAIL_BYTES
    call OUTPUTTING_STRING_TO_CONSOLE
    ret
empty_tail:
    mov DX, offset EMPTY_COM_TAIL
    call OUTPUTTING_STRING_TO_CONSOLE
    ret
COMMAND_TAIL ENDP
;==============================================
CONTAIN_ENVIRONMENT PROC near
	mov DX, offset CONTENT_STRING
	call OUTPUTTING_STRING_TO_CONSOLE
	xor DI, DI
    mov DS, DS:[2Ch]
    mov DL, DS:[DI]
reading_string:
	cmp DL, 000h
	je check_end
	mov AH, 02h
	int 21h
	inc DI
	mov DL, DS:[DI]
	jmp reading_string
check_end:	
	inc DI
	mov DL, DS:[DI]
	cmp DL, 000h
	je end_of_procedure
	mov DL, 0Ah
	mov AH, 02h
	int 21h
	jmp reading_string
end_of_procedure:
	mov DL, 0Ah
	mov AH, 02h
	int 21h
	add di, 2
read_way:
	cmp DL, 000h
	je real_end_of_procedure
	mov AH, 02h
	int 21h
	inc DI
	mov DL, DS:[DI]
	jmp read_way
real_end_of_procedure:
	mov DL, 0Ah
	mov AH, 02h
	int 21h
	ret
CONTAIN_ENVIRONMENT ENDP
;==============================================
BEGIN:
	
	call UNREACHABLE_PSP_MEM
	call SEGMENT_ADDRESS_ENVIRONEMNT
	call COMMAND_TAIL
	call CONTAIN_ENVIRONMENT

	xor AL, AL

	MOV AH, 01H 
	INT 21H

	mov AH, 4Ch
	int 21H
LAB2 ENDS
	END START	