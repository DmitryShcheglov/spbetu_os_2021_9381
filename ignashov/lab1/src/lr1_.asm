AStack SEGMENT STACK
AStack ENDS

DATA SEGMENT
PC_Type			db	'PC Type:  ', 0dh, 0ah,'$'
Mod_numb		db	'Modification number:  .  ', 0dh, 0ah,'$'
OEM				db	'OEM:   ', 0dh, 0ah, '$'
S_numb	    db	'Serial Number:       ', 0dh, 0ah, '$'
DATA ENDS

CODE SEGMENT
	ASSUME CS:CODE,DS:DATA,SS:AStack
;���������
;-----------------------------------------------------
TETR_TO_HEX PROC near
	and AL,0Fh
	cmp AL,09
	jbe NEXT
	add AL,07
NEXT: add AL,30h
	ret
TETR_TO_HEX ENDP
;-------------------------------
BYTE_TO_HEX PROC near
; ���� � AL ����������� � ��� ������� �����. ����� � AX
	push CX
	mov AH,AL
	call TETR_TO_HEX
	xchg AL,AH
	mov CL,4
	shr AL,CL
	call TETR_TO_HEX ;� AL ������� �����
	pop CX ;� AH �������
	ret
BYTE_TO_HEX ENDP
;-------------------------------
WRD_TO_HEX PROC near
;������� � 16 �/� 16-�� ���������� �����
; � AX - �����, DI - ����� ���������� �������
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
; ������� � 10�/�, SI - ����� ���� ������� �����
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
;-------------------------------
; ���
main:
	push ds
	sub ax, ax
	push ax
	mov ax, DATA
	mov ds, ax
;PC_Type
	push es
	push bx
	push ax
	mov bx, 0F000h
	mov es, bx
	mov ax, es:[0FFFEh]
	mov ah, al
	call BYTE_TO_HEX
	lea bx, PC_Type
	mov [bx+9], ax; �������� �� ����� ��������, �������� � PC_Type �� ������
	pop ax
	pop bx
	pop es

	mov ah, 30h; ������������� �������� ��������� ���������� � MS DOS
	int 21h

;Mod_numb
	push ax
	push si
	lea si, Mod_numb; � si ����� Mod_numb
	add si, 21; ��������� �� 21 ������
	call BYTE_TO_DEC; al - Basic version number
	add si, 3; ��� �� ���
	mov al, ah
	call BYTE_TO_DEC; al - Modification number
	pop si
	pop ax

;OEM
	mov al, bh
	lea si, OEM
	add si, 7
	call BYTE_TO_DEC; al - OEM number

;S_numb
	mov al, bl
	call BYTE_TO_HEX; al - 24b number
	lea di, S_numb
	add di, 15
	mov [di], ax
	mov ax, cx
	lea di, S_numb
	add di, 20
	call WRD_TO_HEX

;Output
	mov AH,09h	
	lea DX, PC_Type
	int 21h
	lea DX, Mod_numb
	int 21h
	lea DX, OEM
	int 21h
	lea DX, S_numb
	int 21h

; ����� � DOS
	xor AL,AL
	mov AH,4Ch
	int 21H
CODE ENDS
	END main
