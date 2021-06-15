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
	VAL_KEY 	db 0

START_CODE:
    mov KEEP_AX, ax
    mov KEEP_SP, sp
    mov KEEP_SS, SS
    mov ax, seg INT_STACK
    mov ss, ax
    mov ax, offset INT_STACK
    add ax, 64
    mov sp, ax	

    push ax
    push bx
    push cx
    push dx
    push si
    push es
    push ds
    mov ax, seg VAL_KEY
    mov ds, ax
    
    in al, 60h ;Cчитать ключ
    cmp al, REQ_KEY_1
    je CHG_1_I
	
    cmp al, REQ_KEY_2
    je CHG_2_N
	
    cmp al, REQ_KEY_3
    je CHG_3_T
    
    pushf
    call dword ptr CS:KEEP_IP
    jmp END_OF_INT

CHG_1_I:
    mov VAL_KEY, 'z'
    jmp do_req
CHG_2_N:
    mov VAL_KEY, 'x'
    jmp do_req
CHG_3_T:
    mov VAL_KEY, 'c'

do_req:
    in al, 61h ;Взять значение порта управления клавиатурой
    mov ah, al ;Сохранить его
    or al, 80h ;Установить бит разрешения для клавиатуры
    out 61h, al ;И вывести его в управляющий порт
    xchg al, al ;Извлечь исходное значение порта
    out 61h, al ;И записать его обратно
    mov al, 20h ;Послать сигнал конца прерывания контроллеру прерываний 8259
    out 20h, al
  
LOOP_PRINT:
    mov ah, 05h
    mov cl, VAL_KEY
    mov ch, 00h
    int 16h
    or 	al, al
    jz 	END_OF_INT
    mov ax, 0040h
    mov es, ax
    mov ax, es:[1ah]
    mov es:[1ch], ax
    jmp LOOP_PRINT

END_OF_INT:
    pop  ds
    pop  es
    pop	 si
    pop  dx
    pop  cx
    pop  bx
    pop	 ax

    mov  sp, KEEP_SP
    mov  ax, KEEP_SS
    mov  ss, ax
    mov  ax, KEEP_AX

    mov  al, 20h
    out  20h, al
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
	LOAD_MES   db 'interruption loaded', 0dh, 0ah, '$'
    NOT_LOADED_MES db 'interruption not loded', 0dh, 0ah, '$'
   	ALR_LOADED_MES db 'interruption already installed', 0dh, 0ah, '$'
	UNLOAD_MES		db 'interruption reloaded', 0dh, 0ah, '$'
DATA ENDS

END Main 