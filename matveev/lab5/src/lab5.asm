ASSUME CS:CODE, DS:DATA, SS:ASTACK

ASTACK SEGMENT STACK 
	DW 64 DUP(?)
ASTACK ENDS

CODE SEGMENT
;----------------------------
WRITE PROC NEAR ;Вывод на экран сообщения
		push ax
		mov  ah, 09h
	    int  21h
	    pop	 ax
	    ret
WRITE ENDP
;----------------------------
USR_INTER PROC FAR
	jmp START_CODE
	ADDR_PSP1   dw 0 ;offset 3
	ADDR_PSP2   dw 0 ;offset 5
	KEEP_IP 	dw 0 ;offset 7
	KEEP_CS 	dw 0 ;offset 9
	SIGN 	dw 0ABCDh ;offset 11
	REQ_KEY_1	db 02h
	REQ_KEY_2	db 03h
	REQ_KEY_3	db 04h
	INT_STACK	dw 64 dup (?)
	KEEP_SS		dw 0
	KEEP_AX		dw 0
	KEEP_SP		dw 0

START_CODE:
	mov KEEP_SS, ss
 	mov KEEP_SP, sp
 	mov KEEP_AX, ax
 	mov ax, seg INT_STACK
 	mov ss, ax
 	mov sp, 0
 	mov ax, KEEP_AX  
	
	mov ax,0040h
	mov es,ax
	mov al,es:[17h]
	and al,00000010b
	jnz stand_set
	
	in al,60h ;Cчитать ключ
	cmp al, REQ_KEY_1
	je 	CHG_1_I 
		
	cmp al, REQ_KEY_2
	je 	CHG_N_T 
		
	cmp al, REQ_KEY_3
	je 	CHG_3_T 
		
	mov ss, KEEP_SS 
 	mov sp, KEEP_SP
	
	stand_set:
		pop es
		pop ds
		pop dx
		mov ax, CS:KEEP_AX
		mov sp, CS:KEEP_SP
		mov ss, CS:KEEP_SS
		jmp dword ptr cs:[KEEP_IP]
	CHG_1_I:
		mov cl, 'I'
		jmp do_req
	CHG_N_T:
		mov cl, 'N'
		jmp do_req
	CHG_3_T:
		mov cl, 'T'
		jmp do_req

	do_req:
		in al,61h	;Взять значение порта управления клавиатурой
		mov ah,al	;Сохранить его
		or al,80h	;Установить бит разрешения для клавиатуры
		out 61h,al	;И вывести его в управляющий порт
		xchg ah, al	;Извлечь исходное значение порта
		out 61h,al	;И записать его обратно
		mov al,20h	;Послать сигнал конца прерывания контроллеру прерываний 8259 
		out 20h,al	
		
		push bx
		push cx
		push dx	
	
		mov ah, 05h ;функция, позволяющая записать символ в буфер клавиатуры
		mov ch, 00h ;символ в CL уже занесён ранее, осталось обнулить CH	
		int 16h
		or 	al, al	;проверка переполнения буфера
		jnz SKIP 	;если переполнен - идём в skip
		jmp END_OF_USR_INTER	;иначе выходим
	
	SKIP: 			;очищаем буфер
		push es
		push si
		mov ax, 0040h
		mov es, ax
		mov si, 001ah
		mov ax, es:[si] 
		mov si, 001ch
		mov es:[si], ax	
		pop si
		pop es
		
	END_OF_USR_INTER:
		pop dx    
		pop cx
		pop bx	
		mov ax, KEEP_SS
		mov ss, ax
		mov ax, KEEP_AX
		mov sp, KEEP_SP
		iret
USR_INTER ENDP
;----------------------------
last_byte:
CHECK_INTSET PROC NEAR	;Проверка установки прерывания
	push bx
	push dx
	push es

	mov ah, 35h	;Получение вектора прерываний
	mov al, 09h	;Функция выдает значение сегмента в ES, смещение в BX
	int 21h

	mov dx, es:[bx + 11]
	cmp dx, 0ABCDh ;Проверка на совпадение кода прерывания 
	je INSTALLED
	mov al, 00h
	jmp END_CHECK_INTSET

INSTALLED: ; процедура вернёт 1 если прерывание установлено
	mov al, 01h
	jmp END_CHECK_INTSET

END_CHECK_INTSET:
	pop es
	pop dx
	pop bx
	ret
CHECK_INTSET ENDP
;----------------------------
UN_CHECK PROC NEAR ;Проверка на то, не ввёл ли пользователь /un
	push es
	mov ax, ADDR_PSP1
	mov es, ax

	cmp byte ptr es:[82h], '/'		
	jne END_UN_CHECK
	cmp byte ptr es:[83h], 'u'		
	jne END_UN_CHECK
	cmp byte ptr es:[84h], 'n'
	jne END_UN_CHECK
	mov al, 1h

END_UN_CHECK:
	pop es
	ret
UN_CHECK ENDP
;----------------------------
REDEF_INT PROC NEAR ;Cохранение стандартного обработчика прерываний и загрузка пользовательской версии
	push ax
	push bx
	push dx
	push es
	; получаем адрес обработчика прерывания (старого) для того чтобы сохранить
	mov ah, 35h ;функция получения вектора
	mov al, 09h ; номер вектора
	int 21h
	; на выходе в ES:BX = адрес обработчика прерывания
	;возвращает значение вектора прерывания для INT (AL);
	mov KEEP_IP, bx	;Запоминаем смещение и сегмент
	mov KEEP_CS, es

	push ds
	lea dx, USR_INTER
	mov ax, seg USR_INTER
	mov ds, ax
	mov ah, 25h ; функция установки вектора 
	mov al, 09h ; номер вектора
	int 21h     ; меняем прерывание
	pop ds

	lea dx, LOAD_MES 
	call WRITE 

	pop es
	pop dx
	pop bx
	pop ax
	
	ret
REDEF_INT ENDP
;----------------------------
RESTORE_INT PROC NEAR	;Выгрузка обработчика прерывания (восстановленение старого)
	push ax
	push bx
	push dx
	push es
	
	mov ah, 35h
	mov al, 09h
	int 21h

	cli;сбрасывает флаг прерывания в регистре флагов. 
	;Когда этот флаг сброшен, процессор игнорирует все прерывания (кроме NMI)от внешних устройств
	push ds            
	mov dx, es:[bx + 7]   
	mov ax, es:[bx + 9]   
	mov ds, ax
	mov ah, 25h
	mov al, 09h
	int 21h
	pop ds
	sti
	
	lea dx, UNLOAD_MES
	call WRITE 

	push es ;Удаление MCB
	mov cx,es:[bx+3]
	mov es,cx
	mov ah,49h ; Освободить распределенный блок памяти
	int 21h
	
	pop es
	mov cx,es:[bx+5]
	mov es,cx ; es - сегментный адрес (параграф) освобождаемого блока памяти
	int 21h

	pop es
	pop dx
	pop bx
	pop ax
	
	mov ah, 4Ch	;Выход из программы через функцию 4C
	int 21h
	ret
RESTORE_INT ENDP
;----------------------------
MAIN  PROC FAR
    mov bx,2Ch
	mov ax,[bx]
	mov ADDR_PSP2,ax
	mov ADDR_PSP1,ds  ;сохранение PSP
	mov dx, ds 
	xor ax,ax    
	xor bx,bx
	mov ax,data  
	mov ds,ax 
	xor dx, dx

	call UN_CHECK ;Проверка на введение /un 
	cmp al, 01h
	je TRY_TO_UNLOAD		


	call CHECK_INTSET  ;Проверка не является ли программа резидентной
	cmp al, 01h
	jne NEED_TO_REDEF

ALREADY_INSTALLED:
	lea dx, ALR_LOADED_MES ;Программа уже загружена
	call WRITE
	jmp END_OF_MAIN

;Загрузка пользовательского прерывания
NEED_TO_REDEF: 
	call REDEF_INT 
	lea dx, last_byte
	mov cl, 04h
	shr dx, cl
	add dx, 1Bh
	mov ax, 3100h
	int 21h
	
;Выгрузка  пользовательского прерывания    
TRY_TO_UNLOAD:
	call CHECK_INTSET
	cmp al, 1h
	jne NOT_LOADED
	call RESTORE_INT
	jmp END_OF_MAIN

;Прерывание выгружено
NOT_LOADED: 
	lea dx, NOT_LOADED_MES
	call WRITE
	
END_OF_MAIN:
	mov ah, 4Ch
	int 21h
MAIN  	ENDP
CODE 	ENDS

DATA SEGMENT
	LOAD_MES   db 'USER INTERRUPTION IS LOADING NOW', 0dh, 0ah, '$'
    NOT_LOADED_MES db 'USER INTERRUPTION IS NOT LOADED', 0dh, 0ah, '$'
   	ALR_LOADED_MES db 'USER INTERRUPTION IS ALREADY LOADED', 0dh, 0ah, '$'
	UNLOAD_MES		db 'USER INTERRUPTION IS RESTORED', 0dh, 0ah, '$'
DATA ENDS

END Main 