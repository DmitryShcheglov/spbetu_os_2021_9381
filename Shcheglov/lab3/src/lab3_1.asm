LAB3 SEGMENT
	ASSUME CS: LAB3, DS:LAB3, ES: NOTHING, SS:NOTHING
	ORG 100H

START: 
	JMP BEGIN

;ДАННЫЕ

ACCESSED_MEMORY db 'Number of accessed memory:        bytes', 0Dh, 0Ah, '$'
EXTENDED_MEM db 'Size of extended memory:        bytes', 0Dh, 0Ah, '$'
BLOCK_MCB_NUM db 'MCB  : $'
PSP_ADDRESS db 'Segment address of PSP:       $'
SIZE_OF_AREA db 'Size of area:         $'
SDSC db 'SD/SC: $'
STRING_WITH_CARRY db 0Dh, 0Ah, '$'

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
WRITE_NUMBER_MEM PROC near
	mov BX, 16
	mul BX
	mov BX, 10
	xor CX,CX
division:
	div BX
	push DX
	inc CX
	xor DX, DX
	cmp AX, 0
	jne division
writing:
	pop DX
	or DL, 30h
	mov [SI], DL
	inc SI
	loop writing
	ret
WRITE_NUMBER_MEM ENDP
;==============================================
OUTPUTTING_MCB PROC near
	push AX
    push BX
    push CX
    push DX
    push SI
	mov AH, 52h
	int 21h
	mov AX, ES:[BX-2]
    mov ES, AX
    xor CX, CX
	inc CX
reading_MCB:
;номер блока МСВ(итерация)
	mov SI, offset BLOCK_MCB_NUM
	add SI, 4
	mov AL, CL
	push CX
	call BYTE_TO_DEC
	mov DX, offset BLOCK_MCB_NUM
	call OUTPUTTING_STRING_TO_CONSOLE
;адрес PSP
	mov DI, offset PSP_ADDRESS
	add DI, 27
	mov AX, ES:[1]
	call WRD_TO_HEX
	mov DX, offset PSP_ADDRESS
	call OUTPUTTING_STRING_TO_CONSOLE
;Размер участка
	mov AX, ES:[3]
	push AX
	mov SI, offset SIZE_OF_AREA
	add SI, 14
	call WRITE_NUMBER_MEM
	mov DX, offset SIZE_OF_AREA
	call OUTPUTTING_STRING_TO_CONSOLE
;SCSD участок
	mov DX, offset SDSC
	call OUTPUTTING_STRING_TO_CONSOLE
	xor CX, CX
	xor DI, DI
reading_SCSD:
	mov DL, ES:[DI+8]
	mov AH, 02h
	int 21h
	inc DI
	inc CX
	cmp CX, 8
	jne reading_SCSD
;Проверка на последний элемент
	mov DX, offset STRING_WITH_CARRY
	call OUTPUTTING_STRING_TO_CONSOLE
	mov AL, ES:[0]
	cmp AL, 5Ah
	je end_of_proc
	pop AX
	pop CX
    mov DX, ES
    add AX, DX
    inc AX
    inc CX
    mov ES, AX
	jmp reading_MCB
end_of_proc:
	pop AX
	pop CX
    pop SI
    pop DX
    pop CX
    pop BX
    pop AX
	ret
OUTPUTTING_MCB ENDP
;==============================================
BEGIN:
;количество доступной памяти
	mov AH, 4AH
	mov BX, 0FFFFh
	int 21h
  	mov AX, BX
   	mov SI, offset ACCESSED_MEMORY
   	add SI, 27
	call WRITE_NUMBER_MEM
	mov DX, offset ACCESSED_MEMORY
	call OUTPUTTING_STRING_TO_CONSOLE
;количество расширенной памяти
	mov AL, 30h
    out 70h, AL
    in AL, 71h
    mov BL, AL
    mov AL, 31h
    out 70h, AL
    in AL, 71h
	mov BH, AL
	mov AX, BX
	mov SI, offset EXTENDED_MEM
	add SI, 25
	call WRITE_NUMBER_MEM
	mov DX, offset EXTENDED_MEM
	call OUTPUTTING_STRING_TO_CONSOLE
;цепочка блоков управления памятью
	call OUTPUTTING_MCB

	xor AL, AL
	mov AH, 4Ch
	int 21H
LAB3 ENDS
	END START