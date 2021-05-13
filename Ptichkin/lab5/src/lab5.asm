CODE SEGMENT
ASSUME CS: CODE, DS: DATA, SS: MY_STACK

MY_STACK  segment stack
 dw  256 dup(0)
MY_STACK  ends

MY_INTERRUPTION PROC FAR
    jmp  Start

INTERRUPTION_DATA:
    keep_ip dw 0
    keep_cs dw 0
    keep_psp dw 0
    keep_ax dw 0
    keep_ss dw 0
    keep_sp dw 0
	key_value db 0
    new_stack dw 256 dup(0)
    signature dw 6666h

START:
    mov keep_ax, ax
    mov keep_sp, sp
    mov keep_ss, ss
    mov ax, seg new_stack
    mov ss, ax
    mov ax, offset new_stack
    add ax, 256
    mov sp, ax

    push ax
    push bx
    push cx
    push dx
    push si
    push es
    push ds
    mov ax, seg key_value
    mov ds, ax

    in al, 60h ;считывание ключа
    cmp al, 2Dh  
    je key_x
    cmp al, 15h  
    je key_y
    cmp al, 2Ch   
    je key_z

    pushf
    call dword ptr cs:keep_ip
    jmp END_INTERRUPTION

key_x:
    mov key_value, 'a'
    jmp NEXT_KEY
key_y:
    mov key_value, 'b'
    jmp NEXT_KEY
key_z:
    mov key_value, 'c'

NEXT_KEY:
    in al, 61h
    mov ah, al
    or 	al, 80h
    out 61h, al
    xchg al, al
    out 61h, al
    mov al, 20h
    out 20h, al

PRINT_KEY:
    mov ah, 05h
    mov cl, key_value
    mov ch, 00h
    int 16h
    or 	al, al
    jz 	END_INTERRUPTION
    mov ax, 40h
    mov es, ax
    mov ax, es:[1ah]
    mov es:[1ch], ax
    jmp PRINT_KEY


END_INTERRUPTION:
    pop  ds
    pop  es
    pop	 si
    pop  dx
    pop  cx
    pop  bx
    pop	 ax

    mov sp, keep_sp
    mov ax, keep_ss
    mov ss, ax
    mov ax, keep_ax

    mov  al, 20h
    out  20h, al
    iret
MY_INTERRUPTION ENDP
 _end:

IS_INTERRUPTION_LOAD proc ;Проверка установки прерывания
    push ax
    push bx
    push si

    mov  ah, 35h
    mov  al, 09h
    int  21h
    mov  si, offset signature
    sub  si, offset MY_INTERRUPTION
    mov  ax, es:[bx + si]
    cmp	 ax, signature
    jne  END_PROC
    mov  is_load, 1

END_PROC:
    pop  si
    pop  bx
    pop  ax
    ret
    IS_INTERRUPTION_LOAD ENDP

LOAD_INTERRUPTION  proc   ;Cохранение стандартного обработчика прерываний и загрузка пользовательского
    push ax
    push bx
    push cx
    push dx
    push es
    push ds

    mov ah, 35h
    mov al, 09h
    int 21h
    mov keep_cs, es
    mov keep_ip, bx
    mov ax, seg MY_INTERRUPTION
    mov dx, offset MY_INTERRUPTION
    mov ds, ax
    mov ah, 25h
    mov al, 09h
    int 21h
    pop ds

    mov dx, offset _end
    mov cl, 4h
    shr dx, cl
    add	dx, 10fh
    inc dx
    xor ax, ax
    mov ah, 31h
    int 21h

    pop es
    pop dx
    pop cx
    pop bx
    pop ax
ret
LOAD_INTERRUPTION  ENDP

UNLOAD_INTERRUPTION proc  ;Восстановление старого обработчика прерывания
    cli
    push ax
    push bx
    push dx
    push ds
    push es
    push si

    mov ah, 35h
    mov al, 09h
    int 21h
    mov si, offset keep_ip
    sub si, offset MY_INTERRUPTION
    mov dx, es:[bx + si]
    mov ax, es:[bx + si + 2]

    push ds
    mov ds, ax
    mov ah, 25h
    mov al, 09h
    int 21h
    pop ds

    mov ax, es:[bx + si + 4]
    mov es, ax
    push es
    mov ax, es:[2ch]
    mov es, ax
    mov ah, 49h
    int 21h
    pop es
    mov ah, 49h
    int 21h

    sti

    pop si
    pop es
    pop ds
    pop dx
    pop bx
    pop ax

ret
UNLOAD_INTERRUPTION ENDP


IS_UNLOAD  proc  ;Проверка ввёл ли пользователь /un
    push ax
    push es

    mov ax, keep_psp
    mov es, ax
    cmp byte ptr es:[82h], '/'
    jne END_UNLOAD
    cmp byte ptr es:[83h], 'u'
    jne END_UNLOAD
    cmp byte ptr es:[84h], 'n'
    jne END_UNLOAD
    mov is_unl, 1

END_UNLOAD:
    pop es
    pop ax
	ret
IS_UNLOAD ENDP

PRINT PROC NEAR			
	push ax
	mov ah, 9h
	int	21h
	pop ax
	ret
PRINT ENDP

begin proc
    push ds
    xor ax, ax
    push ax
    mov ax, DATA
    mov ds, ax
    mov keep_psp, es
    call IS_INTERRUPTION_LOAD   ;Проверка загрузки прерывания
    call IS_UNLOAD  ;Проверка на введение /un 
    cmp is_unl, 1
    je unload
    mov al, is_load
    cmp al, 1
    jne load
    mov dx, offset loaded_message   ;Прерывание уже загружено
    call PRINT
    jmp end_begin
;Загрузка пользовательского прерывания
load:
    mov dx, offset load_message
    call PRINT
    call LOAD_INTERRUPTION
    jmp  end_begin
;Выгрузка  пользовательского прерывания 
unload:
    cmp  is_load, 1
    jne  not_loaded
    mov dx, offset unloaded_message
    call PRINT
    call UNLOAD_INTERRUPTION
    jmp  end_begin
;Прерывание выгружено
not_loaded:
    mov  dx, offset not_loaded_message
    call PRINT

end_begin:
    xor al, al
    mov ah, 4ch
    int 21h
begin ENDP

CODE ENDS

DATA SEGMENT
    is_load  db  0
    is_unl    db  0
    load_message db  "Interruption was loaded.",0DH, 0AH, '$'
	not_loaded_message db "Interruption not loaded.", 0DH, 0AH, '$'
	unloaded_message db "Interruption was unloaded.", 0DH, 0AH, '$'
	loaded_message db "Interruption already load.", 0DH, 0AH, '$'
DATA ENDS

end begin