
.model small
.stack 100h

; Данные
.data
PC_type_string              db  'PC Type: $'
PC_type_PC                  db  'PC',0dh,0ah,'$'
PC_type_PCXT                db  'PC/XT',0dh,0ah,'$'
PC_type_AT                  db  'AT',0dh,0ah,'$'
PC_type_PS230               db  'PS2 model 30',0dh,0ah,'$'
PC_type_PS25060             db  'PS2 model 50 or 60',0dh,0ah,'$'
PC_type_PS280               db  'PS2 model 80',0dh,0ah,'$'
PC_type_PCjr                db  'PCjr',0dh,0ah,'$'
PC_type_PCconv              db  'PC Convertible',0dh,0ah,'$'
Unknown_string              db  'Unknown:   ',0dh,0ah,'$'
OS_version_string           db  'OS Version: $'
OS_version                  db  '  .  ',0dh,0ah,'$'
OEM_serial_number_string    db  'OEM Serial number: $'
OEM_serial_number           db  '   ',0dh,0ah,'$'
User_serial_number_string   db  'User Serial number: $'
User_serial_number          db  '      ',0dh,0ah,'$'


.code
START:  JMP BEGIN

; Процедуры
;-----------------------------------------------------
TETR_TO_HEX PROC near 
        and AL,0Fh
        cmp AL,09
        jbe NEXT
        add AL,07
NEXT:
        add AL,30h
        ret
TETR_TO_HEX ENDP
;-------------------------------
BYTE_TO_HEX PROC near
; Байт в AL переводится в два символа шестн. числа AX
        push CX
        mov AH,AL
        call TETR_TO_HEX
        xchg AL,AH
        mov CL,4
        shr AL,CL
        call TETR_TO_HEX ; В AL Старшая цифра 
        pop CX           ; В AH младшая цифра
        ret
BYTE_TO_HEX ENDP
;-------------------------------
WRD_TO_HEX PROC near
; Перевод в 16 с/с 16-ти разрядного числа
; в AX - число, DI - адрес последнего символа   
        push BX
        mov BH,AH
        call BYTE_TO_HEX
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
;--------------------------------------------------
BYTE_TO_DEC PROC near
; Перевод AL в 10с/с, SI - адрес поля младшей цифры 
        push CX
        push DX
        xor AH,AH
        xor DX,DX
        mov CX,10
loop_bd:
        div CX
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
;-------------------------------
PRINT   PROC    near
        push    ax
        mov     ah, 09h
        int     21h
        pop     ax
        ret
PRINT   ENDP
;-------------------------------

; КОД
BEGIN:
        mov     ax, @data
        mov     ds, ax
process_type:
        mov     bx, 0f000h
        mov     es, bx
        mov     al, es:[0fffeh]
        
        mov     dx, offset PC_type_string
        call    PRINT
        
        cmp     al, 0ffh
        je      print_type_PC
        cmp     al, 0feh
        je      print_type_PCXT
        cmp     al, 0fbh
        je      print_type_PCXT
        cmp     al, 0fch
        je      print_type_AT
        cmp     al, 0fah
        je      print_type_PS230
        cmp     al, 0fch
        je      print_type_PS25060
        cmp     al, 0f8h
        je      print_type_PS280
        cmp     al, 0fdh
        je      print_type_PCjr
        cmp     al, 0f9h
        je      print_type_PCconv
        jmp     print_type_unknown
        
print_type_PC:
        mov     dx, offset PC_type_PC
        jmp     print_type
print_type_PCXT:
        mov     dx, offset PC_type_PCXT
        jmp     print_type
print_type_AT:
        mov     dx, offset PC_type_AT
        jmp     print_type
print_type_PS230:
        mov     dx, offset PC_type_PS230
        jmp     print_type
print_type_PS25060:
        mov     dx, offset PC_type_PS25060
        jmp     print_type
print_type_PS280:
        mov     dx, offset PC_type_PS280
        jmp     print_type
print_type_PCjr:
        mov     dx, offset PC_type_PCjr
        jmp     print_type
print_type_PCconv:
        mov     dx, offset PC_type_PCconv
        jmp     print_type
print_type_unknown:
        mov     bx, offset Unknown_string
        call    BYTE_TO_HEX
        mov     [bx+9], al
        mov     [bx+10], ah
        mov     dx, bx
        jmp     print_type
print_type:
        call    PRINT
        
process_version:
        mov ah,30h
        int 21h
print_os_version:
        lea     dx, OS_version_string
        call    PRINT
        
        lea     si, OS_version + 1
        push    ax
        call    BYTE_TO_DEC
        pop     ax
        mov     al, ah
        add     si, 4
        call    BYTE_TO_DEC
        lea     dx, OS_version
        call    PRINT
print_oem_number:
        lea     dx, OEM_serial_number_string
        call    PRINT
        
        lea     si, OEM_serial_number + 2
        mov     al, bh
        call    BYTE_TO_DEC
        lea     dx, OEM_serial_number
        call    PRINT
print_serial_number:
        lea     dx, User_serial_number_string
        call    PRINT
        
        lea     di, User_serial_number
        mov     al, bl
        call    BYTE_TO_HEX
        mov     [di], al
        mov     [di+1], ah
        add     di, 5
        mov     ax, cx
        call    WRD_TO_HEX
        lea     dx, User_serial_number
        call    PRINT
exit:
        mov ah, 4ch
        int 21H

        END START ; Конец модуля, START - точка входа
