ASSUME CS:CODE, DS:DATA, SS:MY_STACK
;------------------------------------
MY_STACK SEGMENT STACK 
	DW 64 DUP(?)
MY_STACK ENDS

CODE SEGMENT

INT_COUNT_FUNC PROC FAR ; обработчик прерываниий. печатает количество вызванных прерываний
	jmp PROC_CODE
	
	KEEP_CS dw 0                                ;3 ; для хранения сегмента
	KEEP_IP dw 0                                ;5 и смещения прерывания
	PSP0 dw 0      								;7                      
	PSP1 dw 0	                          		;9 хранит старое значение ES до того, как программа оставлена резидентной в памяти
	INT_COUNT_VAL dw 0FEDCh                ;11 хранит количество вызванных прерываний
	KEEP_SS DW 0							; 13
	KEEP_SP DW 0							; 15
	KEEP_AX DW 0							; 17
	COUNT_MES db 'Count of interruptions: 0000 $' ;19 
	miniStack dw 12 dup(?) ;стек прерываний
PROC_CODE:
; переопределение стека
	mov KEEP_SP, sp 
    mov KEEP_AX, ax
    mov KEEP_SS, ss
    mov sp, offset PROC_CODE
    mov ax, seg miniStack
    mov ss, ax
	
	push ax      
	push bx
	push cx
	push dx

	mov ah, 3h  ; получить позицию и форму курсора
	mov bh, 0h  ; страница
	int 10h
	push dx 
	
	mov ah, 2h ; установить курсор
	mov bh, 0h
	mov bl, 3h
	mov dx, 220h
	int 10h

	push si
	push cx
	push ds
	mov ax, SEG COUNT_MES
	mov ds, ax
	mov si, offset COUNT_MES
	add si, 27

	mov cx, 4
CYCLE:
	mov ah,[si]
	inc ah
	mov [si], ah
	cmp ah, 3Ah
	jne END_INT
	mov ah, 30h
	mov [si], ah	
	dec si
	loop CYCLE
	
END_INT:
    pop ds
    pop cx
	pop si
	
	push es
	push bp
	mov ax, SEG COUNT_MES
	mov es, ax
	mov ax, offset COUNT_MES
	mov bp, ax
	mov ah, 13h
	mov al, 00h
	mov cx, 28
	mov bh, 0
	int 10h
	pop bp
	pop es
	
	pop dx
	mov ah, 02h
	mov bh, 0h
	int 10h

	pop dx
	pop cx
	pop bx
	pop ax  
		
    mov ss, KEEP_SS
    mov ax, KEEP_AX
	mov sp, KEEP_SP
	iret
INT_COUNT_FUNC ENDP
;------------------------------------
MORE_MEMORY PROC
MORE_MEMORY ENDP
;------------------------------------
CHECK_INTSET PROC NEAR;функция проверки установлен ли разработанный вектор прерывания
	push bx
	push dx
	push es

	mov ah, 35h
	mov al, 1Ch
	int 21h

	mov dx, es:[bx + 11] ;INT_COUNT_VAL
	cmp dx, 0FEDCh
	je INT_IS_SET
	mov al, 00h
	jmp END0

INT_IS_SET:
	mov al, 01h
	jmp END0

END0:
	pop es
	pop dx
	pop bx

	ret
CHECK_INTSET ENDP
;------------------------------------
CHECK_UN PROC NEAR; проверка параметра un. процедура загрузки/выгрузки 
	push es
	
	mov ax, PSP0
	mov es, ax
	
	mov al, es:[81h+1]
	cmp al, '/'
	jne END_CHECK_UN

	mov al, es:[81h+2]
	cmp al, 'u'
	jne END_CHECK_UN

	mov al, es:[81h+3]
	cmp al, 'n'
	jne END_CHECK_UN
	mov al, 1h
END_CHECK_UN:
	pop es
	ret
CHECK_UN ENDP

REDEF_INT PROC NEAR;Устанавливает новые обработчики прерывания (25h прерывания int 21h)
	push ax
	push bx
	push dx
	push es
	; получаем адрес обработчика прерывания (старого) для того чтобы сохранить
	mov ah, 35h ;функция получения вектора
	mov al, 1Ch ; номер вектора
	int 21h
	; на выходе в ES:BX = адрес обработчика прерывания
;возвращает значение вектора прерывания для INT (AL); то есть, загружает в BX 0000:[AL*4], а в ES - 0000:[(AL*4)+2].
	mov KEEP_IP, bx
	mov KEEP_CS, es

	push ds
	; установка вектора прерывания: вход: ah = 25h, al = номер прерывания,
	; ds:dx = вектор прерывания: адрес программы обработки прерывания
	;на выходе ничего нет
	mov dx, offset INT_COUNT_FUNC
	mov ax, seg INT_COUNT_FUNC
	mov ds, ax
	mov ah, 25h ; функция установки вектора 
	mov al, 1Ch ; номер вектора
	int 21h ; меняем прерывание
	pop ds

	mov dx, offset LOADING_MES
	call WRITE

	pop es
	pop dx
	pop bx
	pop ax

	ret
REDEF_INT ENDP
;------------------------------------
RESTORE_INT PROC NEAR
	push ax
	push bx
	push dx
	push es

	mov ah, 35h
	mov al, 1Ch
	int 21h

	cli;сбрасывает флаг прерывания в регистре флагов. 
	;Когда этот флаг сброшен, процессор игнорирует все прерывания (кроме NMI)от внешних устройств
	push ds            
	mov dx, es:[bx + 5]   ; загружаем в ds:dx адрес восстанавливаемой программы обработки прерывания ; KEEP_IP
	mov ax, es:[bx + 3]   ;KEEP_CS
	mov ds, ax
	mov ah, 25h
	mov al, 1Ch
	int 21h 
	pop ds
	sti

	mov dx, offset RESTORED_MES
	call WRITE

	push es	
		mov cx, es:[bx + 7] ;PSP0
		mov es, cx
		mov ah, 49h
		int 21h
	pop es
	
	mov cx, es:[bx + 9] ;PSP1
	mov es, cx
	int 21h

	pop es
	pop dx
	pop bx
	pop ax
	
	ret
RESTORE_INT ENDP
;------------------------------------
WRITE PROC NEAR;печать строки
	push ax
	mov ah, 09h
	int	21h
	pop ax
	ret
WRITE ENDP
;------------------------------------
MAIN PROC FAR
	mov bx, 02Ch
	mov ax, [bx]
	mov PSP1, ax
	mov PSP0, ds  
	xor ax, ax    
	xor bx, bx

	mov ax, DATA  
	mov ds, ax    

	call CHECK_UN   ;Загрузка или выгрузка(проверка параметра)
	cmp al, 01h
	je UNLOAD_YET

	call CHECK_INTSET   ;Установлен ли разработанный вектор прерывания
	cmp al, 01h
	jne INTERRUPTI0N_IS_NOT_LOADED
	
	mov dx, offset ALREADY_LOAD_MES	;Уже установлен(выход с сообщение)
	call WRITE
	jmp FINAL
       
	mov ah,4Ch
	int 21h

INTERRUPTI0N_IS_NOT_LOADED:
	call REDEF_INT
	
	mov dx, offset MORE_MEMORY
	mov cl, 04h
	shr dx, cl
	add dx, 1Bh
	mov ax, 3100h
	int 21h
         
UNLOAD_YET:
	call CHECK_INTSET
	cmp al, 00h
	je NOT_SET
	call RESTORE_INT
	jmp FINAL

NOT_SET:
	mov dx, offset NOTLOAD_MES
	call WRITE
    jmp FINAL
	
FINAL: ; ЗАВЕРШЕНИЕ ПРОГРАММЫ
	mov ah, 4Ch
	int 21h
MAIN ENDP

CODE ENDS

DATA SEGMENT
	NOTLOAD_MES db "INTERRUPTION NOT LOAD", 13, 10, '$'
	RESTORED_MES db "INTERRUPTION RESTORED", 13, 10, '$'
	ALREADY_LOAD_MES db "INTERRUPTION IS ALREADY LOAD", 13, 10, '$'
	LOADING_MES db "INTERRUPTION IS LOADING AT THIS MOMENT", 13, 10, '$'
DATA ENDS

END MAIN
