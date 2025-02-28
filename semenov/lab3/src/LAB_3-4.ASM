LAB_3 SEGMENT
	ASSUME CS:LAB_3, DS:LAB_3, ES:NOTHING, SS:NOTHING
	ORG 100H
START: JMP BEGIN
; �����:
First     db '������⢮ ����㯭�� �����: '
Memory_kb db 0, 0, 0
		  db ' �������� '
Memory_b  db 0, 0, 0
		  db ' ����'
		  db 0DH,0AH
		  
		  db '������ ���७��� �����: '
Size_ext  db 0, 0, 0, 0, 0
		  db ' ��������', 0Dh, 0Ah, '$'
_error_	  db '�訡�� � �����: '
ErrorCode db 0, 0, 0, 0Dh, 0Ah, '$'
MCB_adres db '-------------------------', 0Dh, 0Ah, 'MCB-����: '
M_adress  db 0, 0, 0, 0, 0Dh, 0Ah
MCB_type  db 'MCB-⨯: '
_type_    db 0, 0, 0Dh, 0Ah, '$'
PSP_adres db 'PSP-���� �������� ���⪠ �����: '
P_adress  db 0, 0, 0, 0, 0Dh, 0Ah
          db '������ ���⪠: '
Block_kb  db 0, 0, 0
		  db '  �������� '
Block_b   db 0, 0, 0
		  db '  ����'
		  db 0DH,0AH
		  db '��१�ࢨ஢���: '
Reseived  db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0Dh, 0Ah, '$'

; ��� (��楤��):
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
	
; ��� (�ணࠬ��):
	BEGIN:
		; ��宦����� ������⢠ ����㯭�� �����
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
		; ��宦����� ࠧ��� ���७��� �����
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
		; ����� ����� ���� �㭪⮢ �� ��࠭
			mov AH, 09h
			mov DX, offset First
			int 21h
		; �뤥����� �����
			mov ah, 48h
			mov bx, 1000h
			int 21h
		; �஢�ઠ �� ����稥 �訡�� � �� �����
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
		; �᢮�������� ����� �ணࠬ��, ������ ��� �� ��������
			mov AH, 4Ah
			mov BX, 100h
			int 21h
		; �뢮� 楯�窨 ������ �ࠢ����� �������
			mov AH, 52h
			int 21h
			mov AX, ES:[BX-2]
			mov ES, AX
		mainLoop:
		; �⥭�� � ����� ����� MCB (��砫�)
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
		; �⥭�� � ����� ����� MCB (�����)
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