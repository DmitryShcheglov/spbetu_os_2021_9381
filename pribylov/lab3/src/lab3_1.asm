
MAINSEG SEGMENT
        ASSUME CS:MAINSEG, DS:MAINSEG, ES:NOTHING, SS:NOTHING
        ORG 100H
START:  JMP BEGIN
; Данные
available_memory_string         db  '- Available memory: ',09h,'$'
memory_amount                   db  '      Kb,      b',09h,'$'
extended_memory_string          db  '- Extended memory: ',09h,'$'
extended_memory_amount          db  '      Kb',0dh,0ah,'$'
MCB_table                       db  '- MCB table:',0dh,0ah,'$'
MCB_type_string                 db  'MCB type: $'
MCB_type_number                 db  '  ',09h,'$'
PSP_segment_address_string      db  'PSP addr: $'
PSP_segment_address_number      db  '    ',09h,'$'
memory_block_size_string        db  'Mem size: $'
last_8bytes_string              db  'End: $'
endl                            db  0dh,0ah,'$'

; Процедуры
;-----------------------------------------------------
TETR_TO_HEX PROC near 
            and AL,0Fh
            cmp AL,09
            jbe NEXT
            add AL,07
NEXT:       add AL,30h
            ret
TETR_TO_HEX ENDP
;-------------------------------
BYTE_TO_HEX PROC near
; Байт в AL переводится в два символа 16-числа AX
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
WRD_TO_DEC PROC near
; Перевод AX в 10с/с, SI - адрес поля младшей цифры 
            push CX
            push DX
            ;xor AH,AH
            xor DX,DX
            mov CX,10
loop_bd:    div CX
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
end_l:      pop DX
            pop CX
            ret
WRD_TO_DEC ENDP
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
; . . . . . . . . . . . .
; распечатать размер доступной памяти
get_available_memory_info:
            lea     dx, available_memory_string
            call    PRINT
            
            mov     ah, 4Ah
            mov     bx, 0ffffh
            int     21h
            ; в bx находится размер доступной памяти в параграфах (16 байт)
            
            mov     ax, bx
            mov     cl, 6
            shr     ax, cl
            lea     si, memory_amount + 4
            call    WRD_TO_DEC
            
            and     bx, 0111111b
            mov     ax, bx
            mov     cl, 4
            shl     ax, cl
            lea     si, memory_amount + 13
            call    WRD_TO_DEC
            
            lea     dx, memory_amount
            call    PRINT
            lea     dx, endl
            call    PRINT
            
            mov     cx, 4
loop_clear1:
            mov     si, cx
            mov     [memory_amount + si], ' '
            mov     [memory_amount + si + 9], ' '
            loop    loop_clear1
            
; распечатать размер расширенной памяти
get_extended_memory_info:
            lea     dx, extended_memory_string
            call    PRINT
            
            mov     al, 30h
            out     70h, al
            in      al, 71h
            mov     bl, al
            ; в bl - младший байт
            mov     al, 31h
            out     70h, al
            in      al, 71h
            ; в al - старший байт
            
            mov     ah, al
            mov     al, bl
            ;xor     dx,dx
            lea     si, extended_memory_amount + 4
            call    WRD_TO_DEC
            lea     dx, extended_memory_amount
            call    PRINT
            
; респечатать цепочку MCB
get_MCB_chain_info:
            mov     ah, 52h
            int     21h
            mov     ax, es:[bx-2]
            mov     es, ax
            lea     dx, MCB_table
            call    PRINT
; распечатать информацию о текущем MCB
get_MCB_info:
            ; тип MCB - последний или нет
            lea     dx, MCB_type_string
            call    PRINT
            mov     al, es:[00h]
            call    BYTE_TO_HEX
            lea     di, MCB_type_number
            mov     [di], ax
            lea     dx, MCB_type_number
            call    PRINT
            
            ; сегментный адрес PSP
            lea     dx, PSP_segment_address_string
            call    PRINT
            mov     ax, es:[01h]
            lea     di, PSP_segment_address_number + 3
            call    WRD_TO_HEX
            lea     dx, PSP_segment_address_number
            call    PRINT
            
            ; размер участка в байтах
            lea     dx, memory_block_size_string
            call    PRINT
            mov     ax, es:[03h]
            
            mov     bx, ax
            mov     cl, 6
            shr     ax, cl
            lea     si, memory_amount + 4
            call    WRD_TO_DEC
            
            and     bx, 0111111b
            mov     ax, bx
            mov     cl, 4
            shl     ax, cl
            lea     si, memory_amount + 13
            call    WRD_TO_DEC
            
            lea     dx, memory_amount
            call    PRINT
            
            mov     cx, 4
loop_clear2:
            mov     si, cx
            mov     [memory_amount + si], ' '
            mov     [memory_amount + si + 9], ' '
            loop    loop_clear2
            
            ; последние 8 байт
            lea     dx, last_8bytes_string
            call    PRINT
            mov     bx, 8
loop_output_8_bytes:
            mov     dl, es:[bx]
            mov     ah, 02h
            int     21h
            inc     bx
            cmp     bx, 16
            jne     loop_output_8_bytes
            lea     dx, endl
            call    PRINT
            
            ; проверка на последний блок
            mov     ah, 5ah
            cmp     es:[00h], ah
            je      EXIT
            
            ; переход к следующему блоку, если не последний
            mov     ax, es
            add     ax, es:[03h]
            inc     ax
            mov     es, ax
            jmp     get_MCB_info
            
            
; . . . . . . . . . . . .
; Выход в DOS
EXIT:
            xor     AL,AL
            mov     AH,4Ch
            int     21H
MAINSEG     ENDS
            END START ; Конец модуля, START - точка входа
 
