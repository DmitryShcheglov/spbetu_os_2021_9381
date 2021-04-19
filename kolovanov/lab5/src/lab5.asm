.model small
.stack 100h

.code

INTERRUPT_HANDLER PROC FAR
	jmp interrupt_handler_start

	INTERRUPT_HANDLER_ID DB 0Fh, 0Fh, 0FFh, 00h
	KEEP_CS DW 0h
	KEEP_IP DW 0h
	INT_9_ADDR DD 0h

interrupt_handler_start:
	push ax
	push cx
	
; Получаем байты состояния
	push es
	mov cx, 040h
	mov es, cx
	mov cx, es:[0017h]
	pop es

; Проверяем, зажата ли клавиша Alt. Если да, то проверяем дальше, иначе - переходим на стандартный обработчик
	and cx, 01000b
	cmp cx, 0
	je call_old_int

; Если нажата клавиша 'J' или 'K', то обрабатываем, иначе - переходим на стандартный обработчик
	in al, 60h 
	cmp al, 24h 
	je do_req
	
	cmp al, 25h 
	je do_req

call_old_int:
	pop cx
	pop ax
	jmp dword ptr cs:[INT_9_ADDR]

do_req:
; Посылаем клавиатуре подтверждающий сигнал
	in al, 61H 
	mov ah, al 
	or al, 80h 
	out 61H, al
	xchg ah, al 
	out 61H, al
	
	mov al, 20h
	out 20h, al 
	
; Записываем в буфер символ '!'
write_symbol:
	mov ah, 05h
	mov cl, '!'
	mov ch, 00h
	int 16h
	or al, al
	jz end_int
	
; Очищаем буфер, если он заполнен
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

	iret
INTERRUPT_HANDLER ENDP

GET_INTERRUPT_HANDLER PROC NEAR
	push ax

	mov ah, 35h
	mov al, 09h
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
	mov al, 09h 
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
	mov word ptr INT_9_ADDR, bx
	mov word ptr INT_9_ADDR + 2, es

; Устанавливаем новый обработчик прерываний
	cli 
	mov ax, seg INTERRUPT_HANDLER
	mov dx, offset INTERRUPT_HANDLER
	mov ds, ax 
	mov ah, 25h 
	mov al, 09h
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

; Проверяем наличие флага /un
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
	
; Обработчик прерывания не установлен
handler_isnt_setted:
	mov dx, offset INTERRUPT_HANDLER_NOT_SET_MESSAGE
	call PRINT
	jmp exit

; Устанавливаем обработчик прерываний
set_handler:
	call SET_INTERRUPT_HANDLER

	mov dx, offset interrupt_handler_end
	mov cl, 4
	shr dx, cl 
	inc dx
	mov ah, 31h 
	int 21h

; Проверяем, установлен ли обработчик прерываний
check_handler:
	call CHECK_INTERRUPT_HANDLER
	cmp ax, 0
	je set_handler
	mov dx, offset INTERRUPT_HANDLER_ALREADY_SET_MESSAGE
	call PRINT

; Завершение работы программы
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