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
ROUT PROC FAR
	jmp start_code
	addr_psp1   dw 0 ;offset 3
	addr_psp2   dw 0 ;offset 5
	keep_ip 	dw 0 ;offset 7
	keep_cs 	dw 0 ;offset 9
	sign 	dw 0abcdh ;offset 11
	req_key_1	db 02h
	req_key_2	db 03h
	req_key_3	db 04h
	int_stack	dw 64 dup (?)
	keep_ss		dw 0
	keep_ax		dw 0
	keep_sp		dw 0
	typeKey 	db 0

start_code:
    mov keep_ax, ax
    mov keep_sp, sp
    mov keep_ss, ss
    mov ax, seg int_stack
    mov ss, ax
    mov ax, offset int_stack
    add ax, 64
    mov sp, ax	

    push ax
    push bx
    push cx
    push dx
    push si
    push es
    push ds
    mov ax, seg typeKey
    mov ds, ax
    
    in al, 60h ;cчитать ключ
    cmp al, req_key_1
    je chg_1_p
	
    cmp al, req_key_2
    je chg_2_i
	
    cmp al, req_key_3
    je chg_3_k
    
    pushf
    call dword ptr cs:keep_ip
    jmp end_of_int

chg_1_p:
    mov typeKey, 'p'
    jmp do_req
chg_2_i:
    mov typeKey, 'i'
    jmp do_req
chg_3_k:
    mov typeKey, 'k'

do_req:
    in al, 61h ;взять значение порта управления клавиатурой
    mov ah, al ;сохранить его
    or al, 80h ;установить бит разрешения для клавиатуры
    out 61h, al ;и вывести его в управляющий порт
    xchg al, al ;извлечь исходное значение порта
    out 61h, al ;и записать его обратно
    mov al, 20h ;послать сигнал конца прерывания контроллеру прерываний 8259
    out 20h, al
  
writeKey:
    mov ah, 05h
    mov cl, typeKey
    mov ch, 00h
    int 16h
    or 	al, al
    jz 	end_of_int
    mov ax, 0040h
    mov es, ax
    mov ax, es:[1ah]
    mov es:[1ch], ax
    jmp writeKey

end_of_int:
    pop  ds
    pop  es
    pop	 si
    pop  dx
    pop  cx
    pop  bx
    pop	 ax

    mov  sp, keep_sp
    mov  ax, keep_ss
    mov  ss, ax
    mov  ax, keep_ax

    mov  al, 20h
    out  20h, al
    iret
ROUT ENDP
;----------------------------
last_byte:
IsLoad PROC NEAR	;Проверка установки прерывания
	push bx
	push dx
	push es

	mov ah, 35h	;получение вектора прерываний
	mov al, 09h	;функция выдает значение сегмента в es, смещение в bx
	int 21h

	mov dx, es:[bx + 11]
	cmp dx, 0abcdh ;проверка на совпадение кода прерывания 
	je installed
	mov al, 00h
	jmp end_is_load

installed: ; процедура вернёт 1 если прерывание установлено
	mov al, 01h
	jmp end_is_load

end_is_load:
	pop es
	pop dx
	pop bx
	ret
IsLoad ENDP
;----------------------------
IsUnLoad PROC NEAR ;Проверка на то, не ввёл ли пользователь /un
	push es
	mov ax, ADDR_PSP1
	mov es, ax

	cmp byte ptr es:[82h], '/'		
	jne end_un_check
	cmp byte ptr es:[83h], 'u'		
	jne end_un_check
	cmp byte ptr es:[84h], 'n'
	jne end_un_check
	mov al, 1h

end_un_check:
	pop es
	ret
IsUnLoad ENDP
;----------------------------
LoadResident PROC NEAR ;Cохранение стандартного обработчика прерываний и загрузка пользовательской версии
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
	lea dx, ROUT
	mov ax, seg ROUT
	mov ds, ax
	mov ah, 25h ; функция установки вектора 
	mov al, 09h ; номер вектора
	int 21h     ; меняем прерывание
	pop ds

	lea dx, strld 
	call WRITE 

	pop es
	pop dx
	pop bx
	pop ax
	
	ret
LoadResident ENDP
;----------------------------
UnLoad PROC NEAR	;Выгрузка обработчика прерывания (восстановленение старого)
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
	
	lea dx, struld
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
UnLoad ENDP
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

	call IsUnLoad ;Проверка на введение /un 
	cmp al, 01h
	je try_to_unload		


	call IsLoad  ;Проверка не является ли программа резидентной
	cmp al, 01h
	jne need_to_redef

already_installed:
	lea dx, strald ;Программа уже загружена
	call WRITE
	jmp end_of_main

;Загрузка пользовательского прерывания
need_to_redef: 
	call LoadResident 
	lea dx, last_byte
	mov cl, 04h
	shr dx, cl
	add dx, 1Bh
	mov ax, 3100h
	int 21h
	
;Выгрузка  пользовательского прерывания    
try_to_unload:
	call isload
	cmp al, 1h
	jne not_loaded
	call unload
	jmp end_of_main

;Прерывание выгружено
not_loaded: 
	lea dx, strnld
	call write
	
end_of_main:
	mov ah, 4ch
	int 21h
MAIN  	ENDP

CODE 	ENDS
DATA SEGMENT
	strld   db 'Resident loaded', 0dh, 0ah, '$'
    strnld db 'Resident is not loaded', 0dh, 0ah, '$'
   	strald db 'Resident is already loaded', 0dh, 0ah, '$'
	struld		db 'Resident is unloaded', 0dh, 0ah, '$'
DATA ENDS


END Main 

