AStack    SEGMENT  STACK
          DW 12 DUP(?)    ; Отводится 12 слов памяти
AStack    ENDS

; Данные программы

DATA      SEGMENT

	Message db 'Некорректный формат типа PC: встретилось: '
	Number  dw 0
		db 0DH,0AH,'$'

	FF db 'PC', 0DH,0AH,'$'
	FE db 'PC/XT', 0DH,0AH,'$'
	FC db 'AT', 0DH,0AH,'$'
	FA db 'PC2 модель 30', 0DH,0AH,'$'
	;FC db 'PC2 модель 50 или 60', 0DH,0AH,'$'
	F8 db 'PC2 модель 80', 0DH,0AH,'$'
	FD db 'PCjr', 0DH,0AH,'$'
	F9 db 'PC Convertible', 0DH,0AH,'$'

	Version_xx dw '00'
		   db '.'
	Version_yy dw '00'
		   db 0DH,0AH,'$'
		   
	Serial_m db 'Серийный номер OEM: '
	Serial_n dw 0
	db 0DH,0AH, 'Серийный номер пользователя: '
	Serial_user db 6 dup(0)
	db 0DH,0AH, '$'

DATA      ENDS

; Код программы

CODE      SEGMENT
          ASSUME CS:CODE, DS:DATA, SS:AStack
		  
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
	end_l: pop DX
		pop CX
		ret
	BYTE_TO_DEC ENDP
	
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
	
	Main      PROC  FAR
			push  DS
            sub   AX,AX
            push  AX
			mov   AX, DATA
            mov   DS, AX
		  
			mov AX, 0F000h
			mov ES, AX
			mov BX, 0FFFEh
			mov AL, ES:[BX]
	cmp_1:	cmp AL, 0FFh
			jne cmp_2
			mov dx, offset FF
			jmp end_case
	cmp_2:	cmp AL, 0FEh
			jne cmp_3
	dop:	mov dx, offset FE
			jmp end_case
	cmp_3:	cmp AL, 0FBh
			jne cmp_4
			jmp dop
	cmp_4:	cmp AL, 0FCh
			jne cmp_5
			mov dx, offset FC
			jmp end_case
	cmp_5:	cmp AL, 0FAh
			jne cmp_6
			mov dx, offset FA
			jmp end_case
	cmp_6:	cmp AL, 0F8h
			jne cmp_7
			mov dx, offset F8
			jmp end_case
	cmp_7:	cmp AL, 0FDh
			jne cmp_8
			mov dx, offset FD
			jmp end_case
	cmp_8:	cmp AL, 0F9h
			jne default
			mov dx, offset F9
			jmp end_case
	default: 
			call BYTE_TO_HEX
			mov DI, offset number
			mov word ptr DS:[DI], AX
			mov dx, offset Message
	end_case:
			mov AH,09h
			int 21h
			
			mov AH, 30h
			int 21h
			mov DX, AX
			mov SI, offset Version_xx
			inc SI
			call BYTE_TO_DEC
			mov AL, DH
			mov SI, offset Version_yy
			inc SI
			call BYTE_TO_DEC
			
			mov DX, offset Version_xx
			mov AH,09h
			int 21h
			
			mov AL, BH
			call BYTE_TO_HEX
			mov DI, offset Serial_n
			mov word ptr DS:[DI], AX
			
			mov AL, BL
			call BYTE_TO_HEX
			mov DI, offset Serial_user
			mov word ptr DS:[DI], AX
			mov AX, CX
			mov DI, offset Serial_user
			add DI, 5
			call WRD_TO_HEX
			
			mov DX, offset Serial_m
			mov AH,09h
			int 21h
			
			ret
	Main      ENDP
CODE      ENDS
          END Main