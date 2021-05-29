TESTPC SEGMENT

ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
	 ORG 100H
	 
START: JMP MAIN

;������
segAddrUnvailbleMemory	db	'Segment address of memory:     ',0DH,0AH,'$'	
segAddressEnvironment	db	'Segment address of environment:     ',0DH,0AH,'$'	
tailCommandString		db	'Command line tail: ',0DH,0AH,'$'	
noTail		db	'Tail is empty',0DH,0AH,'$'
tailInfo	db	'  $'	
environmentContent	db	'Environment content:   ',0DH,0AH,'$'	
newLine		db	0DH,0AH,'$'	
path		db	'Loadable module path:',0DH,0AH,'$'	

;������������� 4 ���� �������� al � ���� ����� 16�� �.�. � ������������� � � ���������� ����. 
TETR_TO_HEX PROC near
	and AL,0Fh
	cmp AL,09
	jbe NEXT
	add AL,07
NEXT: 
	add AL,30h
	ret
TETR_TO_HEX ENDP

;������������� al ��� ��� ����� � 16-�� �.�. � ����������� �� � ax
BYTE_TO_HEX PROC near
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

; ������� � 16 �.c 16-�� ���������� �����
; � AX - �����, � � DI - ����� ���������� �������
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

; ������� � 10 �/c. SI - ����� ���� ������� �����
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


PRINT	proc	near
	mov	ah, 09h
	int 21h
	ret
PRINT 	endp

MAIN:
;���������� ����� ����������� ������
	mov	ax, ds:[02h]
	mov	di, offset segAddrUnvailbleMemory
	add	di, 29
	call wrd_to_hex
	mov dx, offset segAddrUnvailbleMemory
	call print 
		
;���������� ����� ����� 
	mov	ax, ds:[2ch]
	mov	di, offset segAddressEnvironment
	add	di, 34
	call wrd_to_hex
	mov	dx, offset segAddressEnvironment
	call	print

;����� ��������� ������
	mov	dx, offset tailCommandString
	call print
	mov	cl, ds:[80h]
	cmp	cl, 0
	je	empty
	xor	si, si
		
tailLoop:
	mov	dl, ds:[81h+si]
	mov	ah, 02h
	int	21h
	inc	si
	dec	cl
	cmp	cl, 0
	jne tailloop
	mov	dx, offset newLine
	call print
	jmp envcon
		
empty:
	mov	dx, offset noTail
	call	print

envcon:
;���������� ������� �����
	mov	dx, offset environmentContent
	call print
	mov	es, ds:[2ch]
	xor	si, si
printStr:
	mov	al, es:[si]
	cmp	al, 0
	jne	printSymbol
	inc si
	mov	al, es:[si]
	mov	dx, offset newLine
	call print
printSymbol:
	mov	dl, al
	mov	ah, 02h
	int	21h
	inc	si
	mov	ax, es:[si]
	cmp	ax, 0001
	jne	printStr
		
		
;���� ������������ ������
	mov	dx, offset path
	call print
	add	si, 2
printSymb:
	mov al, es:[si]
	cmp al, 0
	je	exit
	mov	dl, al
	mov ah, 02h
	int	21h
	inc	si
	jmp	printSymb


exit:	; ����� � DOS
	xor AL,AL
	mov AH,4Ch
	int 21H
TESTPC ENDS
	END START 