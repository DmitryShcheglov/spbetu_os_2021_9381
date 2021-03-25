.model small
.stack 100h

.code

INTERRUPT_HANDLER PROC FAR
	jmp interrupt_handler_start

	INTERRUPT_HANDLER_ID DB 0Fh, 0Fh, 0FFh, 00h
	INTERRUPT_HANDLER_CALL_NUMBER DW 0h
	KEEP_CS DW 0h
	KEEP_IP DW 0h
	CALL_NUMBER_MESSAGE DB "Interrupt calls number: "
	CALL_NUMBER DB "     $"

interrupt_handler_start:
	push ax
	push cx
	push dx
	push si
	push bp
	push es

; Запоминаем позицию курсора
	call GET_CURSOR
	push dx

; Увеличиваем счетчик на 1
	inc word ptr cs:[INTERRUPT_HANDLER_CALL_NUMBER]
	
; Записываем значение счетчика в строку CALL_NUMBER
	mov si, offset CALL_NUMBER + 4
	mov ax, cs:[INTERRUPT_HANDLER_CALL_NUMBER]
	xor dx, dx
	mov cx, 10
loop_bd:
	div cx
	or dl, 30h
	mov cs:[si], dl
	dec si
	xor dx, dx
	cmp ax, 10
	jae loop_bd
	cmp al, 00h
	je print_count
	or al, 30h
	mov cs:[si], al

; Печатаем сообщение и значение счетчика на экран
print_count:
	mov ax, cs
	mov es, ax

	mov cx, 24
	xor dx, dx
	mov bp, offset CALL_NUMBER_MESSAGE
	call PRINT_STRING_ES_BP

	mov cx, 5
	mov dh, 0
	mov dl, 24
	mov bp, offset CALL_NUMBER
	call PRINT_STRING_ES_BP
	
; Восстанавливаем курсор
	pop dx
	call SET_CURSOR

	pop es
	pop bp
	pop si
	pop dx
	pop cx
	pop ax

	mov al, 20h
	out 20h, al 

	iret
INTERRUPT_HANDLER ENDP

PRINT_STRING_ES_BP PROC NEAR 
	push ax 
	push bx 

	mov ah, 13h 
	mov al, 1
	mov bh, 0
	mov bl, 3
	int 10h 

	pop bx 
	pop ax 

	ret 
PRINT_STRING_ES_BP ENDP 

SET_CURSOR PROC NEAR 
	push ax 
	push bx 

	mov ah, 02h 
	mov bh, 00h
	int 10h 

	pop bx 
	pop ax 

	ret 
SET_CURSOR ENDP

GET_CURSOR PROC NEAR 
	push ax 
	push bx 

	mov ah, 03h 
	mov bh, 00h
	int 10h 

	pop bx 
	pop ax 

	ret
GET_CURSOR ENDP

GET_INTERRUPT_HANDLER PROC NEAR
	push ax

	mov ah, 35h
	mov al, 1Ch
	int 21h

	pop ax

	ret
GET_INTERRUPT_HANDLER ENDP

RESTORE_INTERRUPT_HANDLER PROC NEAR
	push ax
	push bx
	push dx
	push es

; Достаем установленный обработчик прерываний
	call GET_INTERRUPT_HANDLER
	push es
	
; Восстанавливаем значение старого обработчика прерываний
	push ds
	cli
	mov ax, es:[KEEP_CS]
	mov dx, es:[KEEP_IP]
	mov ds, ax 
	mov ah, 25h
	mov al, 1Ch 
	int 21h
	sti
	pop ds

	mov dx, offset INTERRUPT_HANDLER_RESTORE_MESSAGE
	call PRINT

; Освобождаем память
	pop es
	mov dx, es
	mov ah, 62h
	int 21h
	mov ax, @code
	sub ax, bx
	sub dx, ax
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
RESTORE_INTERRUPT_HANDLER ENDP

SET_INTERRUPT_HANDLER PROC NEAR
	push ax
	push cx
	push dx
	push es
	push ds

; Достаем установленный обработчик прерываний и сохраняем его
	call GET_INTERRUPT_HANDLER
	mov KEEP_CS, es
	mov KEEP_IP, bx

; Устанавливаем новый обработчик прерываний
	cli 
	mov ax, seg INTERRUPT_HANDLER
	mov dx, offset INTERRUPT_HANDLER
	mov ds, ax 
	mov ah, 25h 
	mov al, 1Ch
	int 21h
	sti

	pop ds
	mov dx, offset INTERRUPT_HANDLER_INSTALL_MESSAGE
	call PRINT

	pop es
	pop dx
	pop cx
	pop ax

	ret
SET_INTERRUPT_HANDLER ENDP

CHECK_INTERRUPT_HANDLER PROC NEAR
	push bx
	push cx
	push si
	push di
	push es
	push ds

; Достаем установленный обработчик прерываний
	call GET_INTERRUPT_HANDLER

; Проверяем сигнатуру
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
CHECK_INTERRUPT_HANDLER ENDP

PRINT PROC NEAR
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
PRINT ENDP

BEGIN:
	mov ax, @data
	mov ds, ax

	cmp byte ptr es:[81h + 1], '/'
	jne check_handler
	cmp byte ptr es:[81h + 2], 'u'
	jne check_handler
	cmp byte ptr es:[81h + 3], 'n'
	jne check_handler

	call CHECK_INTERRUPT_HANDLER
	cmp ax, 0
	je handler_isnt_setted
	call RESTORE_INTERRUPT_HANDLER
	jmp exit

handler_isnt_setted:
	mov dx, offset INTERRUPT_HANDLER_NOT_SET_MESSAGE
	call PRINT
	jmp exit

set_handler:
	call SET_INTERRUPT_HANDLER

	mov dx, offset interrupt_handler_end
	mov cl, 4
	shr dx, cl 
	inc dx
	mov ah, 31h 
	int 21h
	
check_handler:
	call CHECK_INTERRUPT_HANDLER
	cmp ax, 0
	je set_handler
	mov dx, offset INTERRUPT_HANDLER_ALREADY_SET_MESSAGE
	call PRINT

exit:
	xor al, al
	mov ah, 4Ch
	int 21h

interrupt_handler_end:

.data
	INTERRUPT_HANDLER_INSTALL_MESSAGE DB "The interrupt handler is successfully installed.", 0Dh, 0Ah, "$"
	INTERRUPT_HANDLER_ALREADY_SET_MESSAGE DB "The interrupt handler is already installed.", 0Dh, 0Ah, "$"
	INTERRUPT_HANDLER_RESTORE_MESSAGE DB "The interrupt handler was successfully restored.", 0Dh, 0Ah, "$"
	INTERRUPT_HANDLER_NOT_SET_MESSAGE DB "The interrupt handler is not installed yet.", 0Dh, 0Ah, "$"

END BEGIN