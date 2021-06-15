MAIN SEGMENT
 ASSUME CS:MAIN, DS:MAIN, ES:NOTHING, SS:NOTHING
	 ORG 100H
START: 
	JMP BEGIN

;ДАННЫЕ
ACCES_MEM db 'Accesible memory:          bytes', 0DH, 0AH, '$' 
EXT_MEM db 'Extended memory:         kilobytes', 0DH, 0AH, '$' 
MCB_TYPE db 'MCB type:   ', '$'
PSP_ADDRESS db 'PSP address:      ', '$'
SIZE_ db 'Size:         bytes', '$'
SC_SD db 'SC/SD: ', '$'
NEWLINE db 0DH, 0AH, '$'
TAB db 9, '$'
ERROR_ db 'Memory request error',0DH, 0AH, '$' 
GOOD_REQUEST db 'Memory request is successful', 0DH, 0AH, '$' 
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

BYTE_TO_DEC PROC near
; перевод в 10 с/c. SI - адрес поля младшей цифры
 push CX
 push DX
 xor AH,AH
 xor DX,DX
 mov CX,10
loop_bd: div CX
		 or DL,30h
		 mov [SI],DL
		 dec SI
		 xor DX,DX
		 cmp AX,10
		 jae loop_bd
		 cmp AL,00h
		 je end_l
		 or AL,30h
		 mov [SI],AL
end_l: 
	   pop DX
	   pop CX
	   ret
BYTE_TO_DEC ENDP

WORD_TO_DEC PROC near
; перевод в 10 с/c. SI - адрес поля младшей цифры
 push CX
 push DX
 mov CX,10
loop_bd_w: 
		 div CX
		 or DL,30h
		 mov [SI],DL
		 dec SI
		 xor DX,DX
		 cmp AX,10
		 jae loop_bd_w
		 cmp AL,00h
		 je end_l_w
		 or AL,30h
		 mov [SI],AL
end_l_w: 
	   pop DX
	   pop CX
	   ret
WORD_TO_DEC ENDP

WRITE PROC NEAR
	push ax
	mov   AH, 9
    int   21h  ; Вызов функции DOS по прерыванию
	pop ax
    ret
WRITE ENDP

WRITE_TAB PROC NEAR
	push ax
	push dx
	mov dx, offset TAB
	mov   AH, 9
    int   21h  ; Вызов функции DOS по прерыванию
	pop dx
	pop ax
    ret
WRITE_TAB ENDP
	
CLEAN_MEM PROC NEAR; освобождение незанятой памяти при помощи функции 4Ah прерывания 21h
	push ax
	push bx
	
	mov ah, 4Ah
	mov bx, 100h
 	int 21h
	
	pop bx
	pop ax
	ret
CLEAN_MEM ENDP

ASK_MEM PROC NEAR ; запросить  64 кб памяти
	push ax
	push bx
	mov ah, 48h
 	mov bx, 1000h 
 	int 21h
 	call IS_POSSIBLE ; если cf != 0, значит возникла ошибка при выделении памяти
	pop bx
	pop ax
	ret
ASK_MEM ENDP

IS_POSSIBLE PROC NEAR ; обработка завершения функций ядра
	push ax
	lahf
	cmp ah, 0 ; проверка флага CF 
	je success
	mov dx, offset ERROR_
	call WRITE
	pop ax 
	ret
success:
	mov dx, offset GOOD_REQUEST
	call WRITE
	pop ax 
	ret
IS_POSSIBLE ENDP

BEGIN:
;количество доступной памяти

	mov ah, 4Ah  ; при использовании функции 4Аh неиспользованная программой память освобождается
 	mov bx, 0FFFFh ; в bx заносится размер памяти в параграфах, который необходимо оставить программе
 	int 21h ; если занести заведомо больший размер памяти, чем может предоставить ос,
	;то в bx вернётся размер доступной  памяти в параграфах
	
	mov dx, 0
	mov ax, bx
	mov cx, 10h
	mul cx 
	
	mov si, offset ACCES_MEM + 25
	call WORD_TO_DEC
	mov dx, offset ACCES_MEM 
	call WRITE

	call ASK_MEM ; запрос памяти
	call CLEAN_MEM ; освобождение незанятой памяти
	
; размер расширенной памяти
	mov al, 30h ;запись адреса ячейки CMOS
	out 70h, al
	in al, 71h ; чтение младшего байта размера расширенной памяти
	mov bl, al
	mov al, 31h ; запись адреса ячейки CMOS
	out 70h, al
	in al, 71h  ;чтение старшего байта размера расширенной памяти
	
	mov ah, al
	mov al, bl ; теперь ax содержит 16-ую запись размера расширенной памяти
	
	mov si, offset EXT_MEM + 23
	xor dx, dx
	call WORD_TO_DEC
	mov dx, offset EXT_MEM
	call WRITE
	
	mov dx, offset NEWLINE
	call WRITE
	
	
; список блоков управления
get_access: 
	mov ah, 52h
	int 21h
	mov ax, es:[bx - 2]; установить es на адрес начала MCB
	mov es, ax
get_MCB_type:
	mov al, es:[0h]
	call BYTE_TO_HEX
	mov si, offset MCB_TYPE + 10
	mov [si], ax
	mov dx, offset MCB_TYPE
	call WRITE
	call WRITE_TAB
get_PSP_address:
	mov ax, es:[1h]
	mov di, offset PSP_ADDRESS + 17
	call WRD_TO_HEX
	mov dx, offset PSP_ADDRESS
	call WRITE
	call WRITE_TAB
get_size: ; объём памяти MCB
	mov ax, es:[3h]
    mov si, offset SIZE_ + 12
    mov cx, 10h
    mul cx
    call WORD_TO_DEC
    mov dx, offset SIZE_
    call WRITE
	call WRITE_TAB
get_SC_SD:
    mov     bx, 8
    mov     dx, offset SC_SD
    call    WRITE
    mov cx, 8
	fill_8_bytes:
		mov     dl, es:[bx]
		mov     ah, 02h
		int     21h
		inc     bx
		loop    fill_8_bytes
	mov dx, offset NEWLINE
	call WRITE
is_end:
	cmp 	byte ptr es:[0000h], 5Ah  ; проверка на последний блок
    je 	end_	
	mov 	ax, es      ;смещение к следующему блоку
    add 	ax, es:[3h]
    inc 	ax
    mov 	es, ax
    jmp 	get_MCB_type ; переход на новый блок управления
	
end_:
;выход в ДОС
	 xor AL,AL
	 mov AH,4Ch
	 int 21H
MAIN_END:
MAIN ENDS
	   END START 
	   
; КОНЕЦ МОДУЛЯ, START - ТОЧКА ВХОДА