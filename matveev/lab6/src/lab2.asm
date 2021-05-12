MAIN SEGMENT
 ASSUME CS:MAIN, DS:MAIN, ES:NOTHING, SS:NOTHING
	 ORG 100H
START: JMP BEGIN

;ДАННЫЕ
INAC_MEM db 'Segment address of inaccesible memory:     ', 0DH, 0AH, '$' 
ENVIR db 'Segment address of environment:     ', 0DH, 0AH, '$'
TAIL_COM db 'Tail of command string: ', '$'
ENVIR_AREA db 'Environment area content: ', 0DH, 0AH, '$'
MOD_PATH db 'Path of module: ', '$'
buffer db 256 dup('$')
other_info db 256 dup ('$')
path db 256 dup ('$')

;процедуры
TETR_TO_HEX PROC near ;представляет 4 младших бита al в виде цифры 16-ой с.сч. и представляет её в символьном виде
	 and AL,0Fh
	 cmp AL,09
	 jbe NEXT
	 add AL,07
NEXT: 
	 add AL,30h ; результат в al
	 ret
TETR_TO_HEX ENDP
;----------------------------------

BYTE_TO_HEX PROC near
; байт в al переводится в 2 символа шест. числа в AX
	 push CX
	 mov AH,AL
	 call TETR_TO_HEX
	 xchg AL,AH
	 mov CL,4
	 shr AL,CL
	 call TETR_TO_HEX ;в AL старшая цифра
	 pop CX ;в AH 	младшая
	 ret
BYTE_TO_HEX ENDP
;-------------------------------  
WRD_TO_HEX PROC near ; предполагает, что в al - младший байт числа, в ah - старший
; перевод в 16 с/c 16-ти разрядного числа
; в AX - число, DI - адрес последнего символа
	 push BX
	 mov BH,AH
	 call BYTE_TO_HEX ; сначала обработка: число в al -> al - старшая цифра, ah - младшая
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

WRITE PROC NEAR
	push ax
	mov   AH, 9
    int   21h  ; Вызов функции DOS по прерыванию
	pop ax
    ret
WRITE ENDP


;------------------------------- 
GET_SEG_ADR PROC NEAR ;сегментный адрес недоступной памяти
	mov ax, ds:[0002h]
	mov dx, offset INAC_MEM
	mov di, dx
	add di, 42
	call WRD_TO_HEX
	call WRITE
	ret
GET_SEG_ADR ENDP

GET_ENVIR PROC NEAR ;сегментный адрес среды
	mov ax, ds:[002Ch]
	mov dx, offset ENVIR
	mov di, dx
	add di, 35 
	call WRD_TO_HEX
	call WRITE
	ret
	GET_ENVIR ENDP

GET_TAIL_COM PROC NEAR ;хвост командной строки
	;TAIL_COM
	mov dx, offset TAIL_COM
	call WRITE
	
	xor cx, cx
	mov cl, ds:[0080h] ; храним в cx размер аргумента
	
	mov bx, offset buffer
	xor di, di	; индекс приёмника изначально нулевой
	
	cmp cl, 0 ; проверяем на пустоту аргументов командной строки
	je end_of_cycle
	
	mov si, 0081h	; по умолчанию смещение указывается относительно начала ds, поэтому si (источник) будет 81h
	tail:
		mov  al, [si]
		mov  [bx + di], al
		inc di
		inc si
		cmp di, cx ; если индекс равен максимальному количеству - выход из цикла
		jb tail
		
	end_of_cycle:;установка конечных управляющих символов
	mov     byte ptr [bx + di], 0Dh
    mov     byte ptr [bx + di + 1], 0Ah
	
	mov dx, offset buffer
	call WRITE
	ret
GET_TAIL_COM ENDP

GET_CONTENT_AND_PATH PROC near
	mov dx, offset ENVIR_AREA 
	call WRITE
	push ds
	mov ax, ds:[002Ch]; содержимое среды
	mov ds, ax
	xor si, si
	mov di, offset other_info
	content: ; цикл записи содержимого среды из psp в строку
		lodsb 
		cmp al, 00h; встретили 0 - проверяем следующий элемент
		je is_end
		stosb
		jmp content
	is_end:
		lodsb 
		cmp al, 00h ; если и второй 0, то конец среды
		je end_envir
		mov byte ptr es:[di], 0Ah
		inc di
		dec si
		jmp content
	end_envir:
		mov     byte ptr es:[di], 0Dh
		mov     byte ptr es:[di+1], 0Ah
		pop ds
		mov dx, offset other_info
		call WRITE
	get_path: ; получение маршрута
		mov dx, offset MOD_PATH
		call WRITE
		push ds
		mov ax, ds:[002Ch]
		mov ds, ax
		add si, 2 ; теперь si установлен на начало маршрута
		mov di, offset es:path
		path_loop:
			lodsb 
			cmp al, 00h; встретили 0 -  достигли конца пути
			je the_end
			stosb
			jmp path_loop
		the_end:
			mov     byte ptr es:[di], 0Dh
			mov     byte ptr es:[di+1], 0Ah
			pop ds
			mov dx, offset path
			call WRITE
	ret
GET_CONTENT_AND_PATH ENDP

;код
BEGIN: 
	call GET_SEG_ADR
	call GET_ENVIR
	call GET_TAIL_COM
	call GET_CONTENT_AND_PATH
;выход в ДОС
	 xor AL,AL
	 mov ah,01h
	 int 21h
	 mov AH,4Ch
	 int 21H
MAIN ENDS
	   END START 
	   
; КОНЕЦ МОДУЛЯ, START - ТОЧКА ВХОДА