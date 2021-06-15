LB_2 SEGMENT
	ASSUME CS:LB_2, DS:LB_2, ES:NOTHING, SS:NOTHING
	ORG 100H
START: JMP BEGIN
; Данные:
Message db 0DH, 0AH, 'Сегментный адрес недопустимой памяти: '
Adress_1  dw 0, 0
		  db 0DH, 0AH

		db 'Сегментный адрес среды: '
Adress_2  dw 0, 0
		db 0DH, 0AH
		
		db 'Хвост командной строки:$'
Symbol  db 0, '$'
Content db 'Содержимое области среды:', 0DH, 0AH, '$'
Puth 	db 'Путь загружаемого модуля: $'
Enter_	db 0DH, 0AH, '$'
		

; Код (процедуры):
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
	
	PRINT_SYMBOL PROC near
		mov BL, ES:[DI]
		mov Symbol, BL
		int 21h
		inc DI
		ret
	PRINT_SYMBOL ENDP
	
	PRINT_ENTER PROC near
		push DX
		mov DX, offset Enter_
		int 21h
		pop DX
		ret
	PRINT_ENTER ENDP
	
	PRINT_TAB PROC near
		mov Symbol, 09h
		int 21h
		ret
	PRINT_TAB ENDP
	
; Код (программа):
	BEGIN:
			mov AX, ES:0002h
			mov DI, offset Adress_1
			add DI, 3
			call WRD_TO_HEX
			
			mov AX, ES:002Ch
			mov DI, offset Adress_2
			add DI, 3
			call WRD_TO_HEX
			
			mov DX, offset Message
			mov AH,09h
			int 21h
			
			mov CH, 0
			mov CL, ES:0080h
			mov DX, offset Symbol
			mov AH, 09h
			mov DI, 81h
			cmp CX, 0
			je End_loop
	Write_tail:
			call PRINT_SYMBOL
			loop Write_tail
	End_loop:
			call PRINT_ENTER
			
			push DX
			mov DX, offset Content
			int 21h
			pop DX
			
			mov ES, DS:002Ch
			mov DI, 0
			mov CL, 0
			call PRINT_TAB
	Writing:		
			cmp ES:[DI], CL
			jne Further
			call PRINT_ENTER
			call PRINT_TAB
			inc DI
	Further:
			cmp ES:[DI], CL
			je Finish
			call PRINT_SYMBOL
			jmp Writing
	Finish:
			call PRINT_ENTER
			push DX
			mov DX, offset Puth
			int 21h
			POP DX
			
			add DI, 3
	Writing_puth:
			cmp ES:[DI], CL
			je Main_Finish
			call PRINT_SYMBOL
			jmp Writing_puth
	Main_Finish:
			call PRINT_ENTER
			
			xor AL,AL
			mov AH,4Ch
			int 21H
LB_2 ENDS
END START