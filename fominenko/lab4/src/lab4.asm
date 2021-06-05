CODE SEGMENT
	ASSUME CS: CODE, DS: DATA, SS: SSTACK
	
MY_INTERRUPTION PROC FAR
	jmp START
	psp_adr_0 dw 0                           				  
	psp_adr_1 dw 0	                         				  
	keep_cs dw 0                                
	keep_ip dw 0                  
	interruption_set dw 0FEDCh              
	count db 'Interrupts call count: 0000  $'

	keep_ss dw ?
	keep_sp dw ?
	keep_ax dw ?
	INT_STACK dw 64 dup (?)
	END_INT_STACK dw ?
	
START:

	mov keep_ss, ss
	mov keep_sp, sp
	mov keep_ax, ax
	mov ax, cs
	mov ss, ax
	mov sp, offset END_INT_STACK
	
	push ax
	push bx
	push cx
	push dx

	mov ah, 3h			
	mov bh, 0h
	int 10h					
	push dx

	mov ah, 2h
	mov bh, 0h
	mov dx, 220h
	int 10h

	push si
	push cx
	push ds
	mov ax, SEG count
	mov ds, ax
	lea si, count
	add si, 1Ah

	mov ah,[si]
	inc ah
	mov [si], ah
	cmp ah, 3Ah
	jne END_CALC
	mov ah, 30h
	mov [si], ah

	mov bh, [si-1]
	inc bh
	mov [si-1], bh
	cmp bh, 3Ah
	jne END_CALC
	mov bh, 30h
	mov [si-1], bh

	mov ch, [si-2]
	inc ch
	mov [si-2], ch
	cmp ch, 3Ah
	jne END_CALC
	mov ch, 30h
	mov [si-2], ch

	mov dh, [si-3]
	inc dh
	mov [si-3], dh
	cmp dh, 3Ah
	jne END_CALC
	mov dh, 30h
	mov [si-3],dh

END_CALC:
	pop ds
	pop cx
	pop si

	push es
	push bp
	mov ax, SEG count
	mov es, ax
	lea ax, count
	mov bp, ax
	mov ah, 13h
	mov al, 0h
	mov cx, 1Dh
	mov bh, 0
	int 10h

	pop bp
	pop es
	pop dx
	mov ah, 2h
	mov bh, 0h
	int 10h

	pop dx
	pop cx
	pop bx
	pop ax
	
	mov ss, keep_ss
	mov ax, keep_ax
	mov sp, keep_sp
	mov AL, 20H
	out 20H, AL
	iret
MY_INTERRUPTION ENDP

NEED_MEM_AREA PROC
NEED_MEM_AREA ENDP

IS_SET PROC NEAR
	push bx
	push dx
	push es

	mov ah, 35h
	mov al, 1Ch
	int 21h

	mov dx, es:[bx + 11]
	cmp dx, 0FEDCh
	je INT_IS_SET
	mov al, 0h
	jmp POP_REG
INT_IS_SET:
	mov al, 01h
POP_REG:
	pop es
	pop dx
	pop bx
	ret
IS_SET ENDP

IS_LOAD PROC NEAR
	push es

	mov ax, psp_adr_0
	mov es, ax

	mov bx, 82h

	mov al, es:[bx]
	inc bx
	cmp al, '/'
	jne NULL_CMD

	mov al, es:[bx]
	inc bx
	cmp al, 'u'
	jne NULL_CMD

	mov al, es:[bx]
	inc bx
	cmp al, 'n'
	jne NULL_CMD
	mov al, 0001h
NULL_CMD:
	pop es
	ret
IS_LOAD ENDP

LOAD_INTERRUPTION PROC NEAR  
	push ax
	push bx
	push dx
	push es

	mov ah, 35h
	mov al, 1Ch
	int 21h

	mov keep_ip, bx
	mov keep_cs, es

	push ds
	lea dx, MY_INTERRUPTION     
	mov ax, seg MY_INTERRUPTION 
	mov ds, ax

	mov ah, 25h									
	mov al, 1Ch									
	int 21h										
	pop ds

	lea dx, load_process
	call PRINT

	pop es
	pop dx
	pop bx
	pop ax
	ret
LOAD_INTERRUPTION ENDP

UNLOAD_INTERRUPTION PROC NEAR
	push ax
	push bx
	push dx
	push es

	mov ah, 35h
	mov al, 1Ch
	int 21h

	cli
	push ds
	mov dx, es:[bx + 9]
	mov ax, es:[bx + 7]
	mov ds, ax
	mov ah, 25h
	mov al, 1Ch
	int 21h
	pop ds
	sti
	lea dx, restored
	call PRINT

	push es
	mov cx, es:[bx + 3]
	mov es, cx
	mov ah, 49h
	int 21h
	pop es

	mov cx, es:[bx + 5]
	mov es, cx
	int 21h

	pop es
	pop dx
	pop bx
	pop ax
	ret
UNLOAD_INTERRUPTION ENDP

PRINT PROC NEAR			
	push ax
	mov ah, 9h
	int	21h
	pop ax
	ret
PRINT ENDP

MAIN PROC FAR
	mov bx, 2Ch
	mov ax, [bx]
	mov psp_adr_1, ax
	mov psp_adr_0, ds
	sub ax, ax
	xor bx, bx

	mov ax, DATA
	mov ds, ax

	call IS_LOAD   
	cmp al, 1h
	je UNLOAD_START

	call IS_SET   
	cmp al, 1h
	jne INT_NOT_LOADED

	lea dx, loaded	
	call PRINT
	jmp EXIT

	mov ah,4Ch
	int 21h
INT_NOT_LOADED:
	call LOAD_INTERRUPTION

	lea dx, NEED_MEM_AREA
	mov cl, 4h			
	shr dx, cl
	add dx, 1Bh

	mov ax, 3100h		
	int 21h
UNLOAD_START:
	call IS_SET
	cmp al, 0h
	je NOT_SET
	call UNLOAD_INTERRUPTION
	jmp EXIT
NOT_SET:
	lea dx, not_loaded
	call PRINT
EXIT:
	mov ah, 4Ch
	int 21h
MAIN ENDP

CODE ENDS
SSTACK SEGMENT STACK
	DB 64 DUP(?)
SSTACK ENDS

DATA SEGMENT
	not_loaded db "Interruption not loaded.", 0DH, 0AH, '$'
	restored db "Interruption was restored.", 0DH, 0AH, '$'
	loaded db "Interruption already load.", 0DH, 0AH, '$'
	load_process db "Interruption is loading.", 0DH, 0AH, '$'
DATA ENDS

END MAIN