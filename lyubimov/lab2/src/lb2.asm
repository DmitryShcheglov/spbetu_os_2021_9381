MAIN SEGMENT
	ASSUME CS:MAIN, DS:MAIN, ES:NOTHING, SS:NOTHING
	ORG 100h

START:
	jmp BEGIN

restricted_memory_mes DB 'Segment address of restricted memory: $'
restricted_memory_adress DB '    ', 0Dh, 0Ah, '$'
envir_adress_mes DB 'Segment address of the environment: $'
envir_adress DB '    ', 0Dh, 0Ah, '$'
tail_mes DB 'Tail contenet: $'
envir_content_mes DB 'Content of the environment:', 0Dh, 0Ah, '$'
path_mes DB 'Path to the launched module: $'
some_content DB 256 DUP('$')

TETR_TO_HEX PROC NEAR
	and al, 0Fh
	cmp al, 09
	jbe next
	add al, 07
next:
	add al, 30h
	ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC NEAR
	push cx
	mov ah, al
	call TETR_TO_HEX
	xchg al, ah
	mov cl, 4
	shr al, cl
	call TETR_TO_HEX
	pop cx
	ret
BYTE_TO_HEX ENDP

WORD_TO_HEX PROC NEAR
	push bx
	mov bh, ah
	call BYTE_TO_HEX
	mov [di], ah
	dec di
	mov [di], al
	dec di
	mov AL, bh
	call BYTE_TO_HEX
	mov [di], ah
	dec di
	mov [di], al
	pop bx
	ret
WORD_TO_HEX ENDP

PRINT_MES PROC near
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
PRINT_MES ENDP

PRINT_INVALID_MEM PROC NEAR
	mov ax, DS:[0002h]
	mov di, offset restricted_memory_adress + 3
	call WORD_TO_HEX
	mov dx, offset restricted_memory_mes
	call PRINT_MES
	mov dx, offset restricted_memory_adress

	call PRINT_MES
	ret
PRINT_INVALID_MEM ENDP

PRINT_ENVIR_ADRESS PROC NEAR
	mov ax, DS:[002Ch]
	mov di, offset envir_adress + 3
	call WORD_TO_HEX
	mov dx, offset envir_adress_mes
	call PRINT_MES
	mov dx, offset envir_adress

	call PRINT_MES
	ret
PRINT_ENVIR_ADRESS ENDP

PRINT_TAIL PROC NEAR
	mov si, 0081h
	mov di, offset some_content
	mov cl, DS:[0080h]
	xor ch, ch
	rep movsb
	mov byte ptr [di], 0Dh
	mov byte ptr [di+1], 0Ah
	mov byte ptr [di+2], '$'
	mov dx, offset tail_mes
	call PRINT_MES
	mov dx, offset some_content

	call PRINT_MES
	ret
PRINT_TAIL ENDP

PRINT_ENVIR_AND_PATH PROC NEAR
	mov ax, DS:[002Ch]
	mov ds, ax
	xor si, si
	mov di, offset some_content

begin_1:
	mov al, 09h
	stosb
	lodsb
	cmp al, 0h
	je end_1
	stosb

begin_2:
	lodsb
	cmp al, 0h
	je end_2
	stosb
	jmp begin_2

end_2:
	mov al, 0Ah
	stosb
	jmp begin_1

end_1:
	mov byte ptr ES:[di], 0Dh
	mov byte ptr ES:[di+1], '$'
	mov bx, ds
	mov ax, es
	mov ds, ax
	mov dx, offset envir_content_mes
	call PRINT_MES
	mov dx, offset some_content
	call PRINT_MES
	mov di, offset some_content
	mov ds, bx
	lodsb
	lodsb

begin_3:
	lodsb
	cmp al, 0h
	je end_3
	stosb
	jmp begin_3

end_3:
	mov byte ptr ES:[di], 0Ah
	mov byte ptr ES:[di+1], 0Dh
	mov byte ptr ES:[di+2], '$'
	mov ax, es
	mov ds, ax
	mov dx, offset path_mes
	call PRINT_MES
	mov dx, offset some_content

	call PRINT_MES
	ret
PRINT_ENVIR_AND_PATH ENDP

BEGIN:
	call PRINT_INVALID_MEM
	call PRINT_ENVIR_ADRESS
	call PRINT_TAIL
	call PRINT_ENVIR_AND_PATH
	xor al, al
	mov AH, 4Ch
	int 21H
	
MAIN ENDS

END START
