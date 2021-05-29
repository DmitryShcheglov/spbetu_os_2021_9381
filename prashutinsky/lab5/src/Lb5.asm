CODE SEGMENT
	ASSUME CS:CODE, DS:DATA, SS:P_STACK

ROUT PROC FAR
	jmp IH_START

	IH_ID DB 0Fh, 0Fh, 0FFh, 00h
	KEEP_AX DW 0h
	KEEP_CS DW 0h
	KEEP_IP DW 0h
	KEEP_SS DW 0h
	KEEP_SP DW 0h
	KEEP_PSP DW 0h
	INT_9_ADDR DD 0h
	I_STACK DB 128 DUP(0)

IH_START:
	mov KEEP_SS, ss
	mov KEEP_SP, sp
	mov KEEP_AX, ax
	mov ax, seg I_STACK
	mov ss, ax
	mov sp, offset IH_START
	
	push ax
	push cx
	
; �������� ����� ���������
	push es
	mov cx, 040h
	mov es, cx
	mov cx, es:[0017h]
	pop es

; ���������, ������ �� ������� Alt. ���� ��, �� ��������� ������, ����� - ��������� �� ����������� ����������
	and cx, 01000b
	cmp cx, 0
	je call_old_int

; ���� ������ ������� 'J' ��� 'K', �� ������������, ����� - ��������� �� ����������� ����������
	in al, 60h 
	cmp al, 24h 
	je do_req
	
	cmp al, 25h 
	je do_req

call_old_int:
	pop cx
	pop ax
	mov ss, KEEP_SS
	mov sp, KEEP_SP
	mov ax, KEEP_AX
	jmp dword ptr cs:[INT_9_ADDR]

do_req:
; �������� ���������� �������������� ������
	in al, 61H 
	mov ah, al 
	or al, 80h 
	out 61H, al
	xchg ah, al 
	out 61H, al
	
	mov al, 20h
	out 20h, al 
	
; ���������� � ����� ������ '!'
write_symbol:
	mov ah, 05h
	mov cl, '!'
	mov ch, 00h
	int 16h
	or al, al
	jz end_int
	
; ������� �����, ���� �� ��������
	push es
	cli
	mov ax, 0040h
	mov es, ax	
	mov al, es:[001Ah]	
	mov es:[001Ch], al
	sti
	pop es
	jmp write_symbol
	
end_int:
	pop cx
	pop ax
	
	mov al, 20h
	out 20h, al
	
	mov ss, KEEP_SS
	mov sp, KEEP_SP
	mov ax, KEEP_AX
	
	iret
ROUT ENDP

interrupt_handler_end:

RIH PROC NEAR
	push ax
	push bx
	push dx
	push es
	push ds

; ������� ������������� ���������� ����������
	mov ah, 35h
	mov al, 1Ch
	int 21h

; ��������������� �������� ������� ����������� ����������
	cli
	mov ax, es:[KEEP_CS]
	mov dx, es:[KEEP_IP]
	mov ds, ax 
	mov ah, 25h
	mov al, 1Ch 
	int 21h
	sti
	pop ds

	mov dx, offset IHR_MESSAGE
	call PRINT

; ����������� ������
	mov di, offset KEEP_PSP
	mov dx, es:[bx + di]
	mov es, dx
	mov dx, es:[2Ch]
	
	mov ah, 49h
	int 21h

	mov es, dx
	mov ah, 49h
	int 21h

	pop es
	pop dx
	pop bx
	pop ax

	ret
RIH ENDP

SIH PROC NEAR
	push ax
	push bx
	push dx
	push es
	push ds

; ������� ������������� ���������� ���������� � ��������� ���
	mov ah, 35h
	mov al, 1Ch
	int 21h
	mov KEEP_CS, es
	mov KEEP_IP, bx
	mov word ptr INT_9_ADDR, bx
	mov word ptr INT_9_ADDR + 2, es

; ������������� ����� ���������� ����������
	cli 
	mov ax, seg ROUT
	mov dx, offset ROUT
	mov ds, ax 
	mov ah, 25h 
	mov al, 1Ch
	int 21h
	sti

	pop ds
	mov dx, offset IHI_MESSAGE
	call PRINT

	pop es
	pop dx
	pop bx
	pop ax

	ret
SIH ENDP

CIH PROC NEAR
	push bx
	push cx
	push si
	push di
	push es
	push ds

; ������� ������������� ���������� ����������
	mov ah, 35h
	mov al, 1Ch
	int 21h

; ��������� ���������
	mov ax, 0
	mov cl, es:[bx + 3]
	cmp cl, 0Fh
	jne end_check
	mov cl, es:[bx + 4]
	cmp cl, 0Fh
	jne end_check
	mov cl, es:[bx + 5]
	cmp cl, 0FFh
	jne end_check
	mov cl, es:[bx + 6]
	cmp cl, 00h
	jne end_check
	mov ax, 1

end_check:
	pop ds
	pop es
	pop di
	pop si
	pop cx
	pop bx

	ret 
CIH ENDP

PRINT PROC NEAR
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
PRINT ENDP

MAIN PROC FAR
	mov KEEP_PSP, ds
	mov ax, DATA
	mov ds, ax

; ��������� ������� ����� /un
	cmp byte ptr es:[81h + 1], '/'
	jne check_handler
	cmp byte ptr es:[81h + 2], 'u'
	jne check_handler
	cmp byte ptr es:[81h + 3], 'n'
	jne check_handler

	call CIH
	cmp ax, 0
	je handler_isnt_setted
	call RIH
	jmp exit

; ���������� ���������� �� ����������
handler_isnt_setted:
	mov dx, offset IH_NOT_SET_MESSAGE
	call PRINT
	jmp exit

; ������������� ���������� ����������
set_handler:
	call SIH

	mov dx, offset interrupt_handler_end
	mov cl, 4
	shr dx, cl 
	add dx, 1Bh
	mov ah, 31h 
	int 21h

; ���������, ���������� �� ���������� ����������
check_handler:
	call CIH
	cmp ax, 0
	je set_handler
	mov dx, offset IHA_SET_MESSAGE
	call PRINT

; ���������� ������ ���������
exit:
	xor al, al
	mov ah, 4Ch
	int 21h
MAIN ENDP

CODE ENDS

P_STACK SEGMENT STACK
	DW 128 DUP(0)
P_STACK ENDS

DATA SEGMENT
	IHI_MESSAGE DB "The interrupt handler is successfully installed.", 0Dh, 0Ah, "$"
	IHA_SET_MESSAGE DB "The interrupt handler is already installed.", 0Dh, 0Ah, "$"
	IHR_MESSAGE DB "The interrupt handler was successfully restored.", 0Dh, 0Ah, "$"
	IH_NOT_SET_MESSAGE DB "The interrupt handler is not installed yet.", 0Dh, 0Ah, "$"
DATA ENDS

END MAIN