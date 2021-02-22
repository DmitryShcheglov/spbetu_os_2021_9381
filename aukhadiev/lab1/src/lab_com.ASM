TESTPC SEGMENT

        ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
        ORG 100H

START:	jmp BEGIN

OSVersionMessage    db  'OS version:  . ', 0DH, 0AH, '$'
OEMMessage          db  'OEM:   ', 0DH, 0AH, '$'
SerialNumberMessage db  'Serial number:       ', 0DH, 0AH, '$'
PCTypeMessage       db  'PC type: $'
PCTypeAT            db  'AT', 0DH, 0AH, '$'
PCTypePC            db  'PC', 0DH, 0AH,'$'
PCTypeXT            db  'PC/XT', 0DH, 0AH, '$'
PCTypePS2_30        db  'PS2 model 30', 0DH, 0AH, '$'
PCTypePS2_50_60     db  'PS2 model 50 or 60', 0DH, 0AH, '$'
PCTypePS2_80        db  'PS2 model 80', 0DH, 0AH, '$'
PCTypePCjr          db  'PCjr', 0DH, 0AH, '$'
PCTypePCC           db  'PC Convertible', 0DH, 0AH, '$'

;Данные
STRING db 'Значение регистра АХ=    ',0DH,0AH,'$'

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
; байт в AL переводится в два символа шестн. числа в АХ
	push cx
	mov ah, al
	call TETR_TO_HEX
	xchg al, ah
	mov cl, 4
	shr al, cl
	call TETR_TO_HEX ;в AL старшая цифра
	pop cx           ;в АН младшая
	ret
BYTE_TO_HEX ENDP

WRD_TO_HEX PROC NEAR
; Перевод в 16 с/с 16-разрядного числа
;в АХ - число, DI - адрес последнего символа
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
WRD_TO_HEX ENDP

BYTE_TO_DEC PROC NEAR
; Перевод 10 с/с, SI - адрес поля младшей цифры
    push cx
	push dx
	xor ah, ah
	xor dx, dx
	mov cx, 10
loop_bd:
	div cx
	or dl,30h
	mov [si], dl
	dec si
	xor dx, dx
	cmp ax, 10
	jae loop_bd
	cmp al, 00h
	je end_l
	or al, 30h
	mov [si], al
end_l:
	pop dx
	pop cx
	ret
BYTE_TO_DEC ENDP

PRINT_MESSAGE PROC NEAR
    push ax
    mov ah, 09h
    int 21h
    pop ax
    ret
PRINT_MESSAGE ENDP
    
BEGIN:
    ;узнаём информацию о типе ПК
    mov ax, 0F000h
    mov es, ax
    mov al, es:[0FFFEh]
    mov dx, offset PCTypeMessage
    call PRINT_MESSAGE
    
    cmp al, 0FFh
    je PC
    cmp al, 0FEh
    je XT
    cmp al, 0FBh
    je XT
    cmp al, 0FCh
    je AT
    cmp al, 0FAh
    je PS2_30
    cmp al, 0FCh
    je PS2_50_60
    cmp al, 0F8h
    je PS2_80
    cmp al, 0FDh
    je PCjr
    cmp al, 0F9h
    je PCConvert
    
PC:
    mov dx, offset PCTypePC
    jmp printType
XT:
    mov dx, offset PCTypeXT
    jmp printType
AT:
    mov dx, offset PCTypeAT
    jmp printType
PS2_30:
    mov dx, offset PCTypePS2_30
    jmp printType
PS2_50_60:
    mov dx, offset PCTypePS2_50_60
    jmp printType
PS2_80:
    mov dx, offset PCTypePS2_80
    jmp printType
PCjr:
    mov dx, offset PCTypePCjr
    jmp printType
PCConvert:
    mov dx, offset PCTypePCC
    
printType:
    call PRINT_MESSAGE
    
    ;получаем версию ОС
    mov ah, 30h
    int 21h
    
    push ax
    push si
    
    lea si, OSVersionMessage
    add si, 12
    call BYTE_TO_DEC
    add si, 3
    mov al, ah
    call BYTE_TO_DEC
    mov dx, offset OSVersionMessage
    call PRINT_MESSAGE
    pop si
    pop ax
    
    ;Поиск и вывод ОЕМ
    mov al, bh
    lea si, OEMMessage
    add si, 5
    call BYTE_TO_DEC
    mov dx, offset OEMMessage
    call PRINT_MESSAGE
    
    ;Поиск и вывод Serial number
    mov al, bl
    call BYTE_TO_HEX
    lea di, SerialNumberMessage
    add di, 15
    mov [di], ax
    mov ax, cx
    lea di, SerialNumberMessage
    add di, 20
    call WRD_TO_HEX
    mov dx, offset SerialNumberMessage
    call PRINT_MESSAGE
    
    ret
    
TESTPC ENDS
    END START

END START
