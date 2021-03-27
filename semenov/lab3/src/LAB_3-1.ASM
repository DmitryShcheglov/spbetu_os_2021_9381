LAB_3 SEGMENT
	ASSUME CS:LAB_3, DS:LAB_3, ES:NOTHING, SS:NOTHING
	ORG 100H
START: JMP BEGIN
; Данные:
First     db 'Количество доступной памяти: '
Memory_kb db 0, 0, 0
		  db ' килобайт '
Memory_b  db 0, 0, 0
		  db ' байт'
		  db 0DH,0AH
		  
		  db 'Размер расширенной памяти: '
Size_ext  db 0, 0, 0, 0, 0
		  db ' килобайт', 0Dh, 0Ah, '$'
_error_	  db 'Ошибка с кодом: '
ErrorCode db 0, 0, 0, 0Dh, 0Ah, '$'
MCB_adres db '-------------------------', 0Dh, 0Ah, 'MCB-адрес: '
M_adress  db 0, 0, 0, 0, 0Dh, 0Ah
MCB_type  db 'MCB-тип: '
_type_    db 0, 0, 0Dh, 0Ah, '$'
PSP_adres db 'PSP-адрес владельца участка памяти: '
P_adress  db 0, 0, 0, 0, 0Dh, 0Ah
          db 'Размер участка: '
Block_kb  db 0, 0, 0
		  db '  килобайт '
Block_b   db 0, 0, 0
		  db '  байт'
		  db 0DH,0AH
		  db 'Зарезервировано: '
Reseived  db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0Dh, 0Ah, '$'

; Код (процедур):
	TETR_TO_HEX PROC near
		and AL,0Fh
		cmp AL,09
		jbe NEXT
		add AL,07
	NEXT: add AL,30h
		ret
	TETR_TO_HEX ENDP

	BYTE_TO_HEX PROC near
		push CX
		mov AH,AL
		call TETR_TO_HEX
		xchg AL,AH
		mov CL,4
		shr AL,CL
		call TETR_TO_HEX

		pop CX
		ret
	BYTE_TO_HEX ENDP
	
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
	
	WRD_TO_DEC PROC NEAR
		push cx
		push dx
		xor dx, dx
		mov cx, 10
	loop_bd_2:
		div cx
		or dl, 30h
		mov [si], dl
		dec si
		xor dx, dx
		cmp ax, 10
		jae loop_bd_2
		cmp al, 00h
		je end_l_2
		or al, 30h
		mov [si], al
	end_l_2:
		pop dx
		pop cx
		ret
	WRD_TO_DEC ENDP
	
; Код (программа):
	BEGIN:
		; Нахождение количества доступной памяти
			mov AH, 4Ah
			mov BX, 0FFFFh
			int 21h
			
			mov AX, BX
			mov DX, 0h
			mov BX, 40h
			div BX
			mov SI, offset Memory_kb + 2
			call WRD_TO_DEC
			mov AX, DX
			mov BX, 10h
			mul BX
			mov SI, offset Memory_b + 2
			call WRD_TO_DEC
		; Нахождение размера расширенной памяти
			mov al, 30h
			out 70h, al
			in al, 71h
			mov dl, al
			mov al, 31h
			out 70h, al
			in al, 71h
			mov dh, al
			
			mov ax, dx
			mov si, offset Size_ext + 4
			call WRD_TO_DEC
		; Печать первых двух пунктов на экран
			mov AH, 09h
			mov DX, offset First
			int 21h
		; Вывод цепочки блоков управления памятью
			mov AH, 52h
			int 21h
		; Проверка на наличие ошибки и ее печать
			push AX
			lahf
			and AH, 01b
			cmp AH, 0
			je OK
			pop AX
			mov SI, offset ErrorCode + 2
			call WRD_TO_DEC
			mov DX, offset _error_
			mov AH, 09h
			int 21h
			jmp _END_
		OK:
			mov AX, ES:[BX-2]
			mov ES, AX

		mainLoop:
		; Чтение и печать блока MCB (начало)
			mov AX, ES
			mov DI, offset M_adress + 3
			call WRD_TO_HEX

			mov AH, 0
			mov AL, ES:[0]
			call BYTE_TO_HEX
			mov DS:[_type_], AL
			mov DS:[_type_ + 1], AH

			mov AH, 09h
			mov DX, offset MCB_adres
			int 21h

			mov AX, ES:[1]
			
			mov DI, offset P_adress + 3
			call WRD_TO_HEX

			mov AX, ES:[3]
			mov DX, 0h
			mov BX, 40h
			div BX
			mov SI, offset Block_kb + 3
			call WRD_TO_DEC
			mov AX, DX
			mov BX, 10h
			mul BX
			mov SI, offset Block_b + 3
			call WRD_TO_DEC

			mov SI, offset Reseived
			mov DI, 5
			mov CX, 11

		readReservedBytes:
			mov AL, ES:[DI]
			mov byte ptr DS:[SI], AL

			add SI, 1
			add DI, 1
			loop readReservedBytes

			mov DX, offset PSP_adres
			mov AH, 09h
			int 21h
		; Чтение и печать блока MCB (конец)
			mov AL, ES:[0]
			mov BX, ES
			mov DX, ES:[3]
			add DX, 1
			add BX, DX
			mov ES, BX
			cmp AL, 4Dh
			jne _END_
			jmp mainLoop
		_END_:	
			xor AL,AL
			mov AH,4Ch
			int 21H
LAB_3 ENDS
END START