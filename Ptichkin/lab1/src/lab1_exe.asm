DOSSEG
.model small
.stack 100h

.data
Type_PC          db 'PC type - PC',0DH,0AH,'$'
Type_XT          db 'PC type - XT',0DH,0AH,'$'
Type_AT          db 'PC type - AT',0DH,0AH,'$'
Type_PS_30       db 'PC type - PS2 model 30',0DH,0AH,'$'
Type_PS_80       db 'PC type - PS2 model 80',0DH,0AH,'$'
Type_PCjr        db 'PC type - PCjr',0DH,0AH,'$'
Type_PCConvert   db 'PC type - PC Сonvertible',0DH,0AH,'$'
Type_Unknown     db '  ', 0DH, 0AH, '$'

OS_Version_Num   db 'OS version number -   .  ',0DH,0AH,'$'
Num_OEM          db 'OEM number -   ',0DH,0AH,'$'
User_series_num  db '24-bit user series number -       ',0DH,0AH,'$'

.code
START: JMP BEGIN

; Процедуры
TETR_TO_HEX PROC near 
            and AL,0Fh
            cmp AL,09
            jbe NEXT
            add AL,07
NEXT:   add AL,30h
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
; Перевод в 10с/с, SI - адрес поля младшей цифры 
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
end_l: pop DX
      pop CX
      ret
BYTE_TO_DEC ENDP

PRINT  PROC NEAR    ; вывод строки на экран
      push ax
      mov ah, 9h
      int 21H
      pop ax
      ret
PRINT ENDP
;-------------------------------
; КОД
BEGIN:
      mov ax, @data
      mov ds, ax
      ;получаем информацию о типе пк
      mov ax, 0F000h 
      mov es, ax
      mov al, es:[0FFFEh]
      ;сравниваем полученное значение с табличными значениями
      cmp al, 0FFh
      je  type_1  
      cmp al, 0FEh
      je  type_1
      cmp al, 0FBh
      je  type_2
      cmp al, 0FAh
      je  type_3
      cmp al, 0FCh
      je  type_4
      cmp al, 0F8h
      je  type_5
      cmp al, 0FDh
      je  type_6
      cmp al, 0F9h
      je  type_7
      jmp print_type
;выбираем строку соответствующую типу пк      
type_1:
      mov dx, offset Type_PC
      jmp  print_type
type_2:
      mov dx, offset Type_XT
      jmp  print_type
type_3:
      mov dx, offset Type_AT
      jmp  print_type
type_4:
      mov dx, offset Type_PS_30
      jmp  print_type
type_5:
      mov dx, offset Type_PS_80
      jmp  print_type
type_6:
      mov dx, offset Type_PCjr
      jmp  print_type
type_7:
      mov dx, offset Type_PCConvert
      jmp  print_type
unknown:
      call BYTE_TO_HEX
      mov bx, offset Type_Unknown
      mov [bx], al
      mov [bx+1], ah
      mov dx, bx
print_type:
      ;печатаем тип пк
      call PRINT
      ;узнаём информацию о версии ОС и серийные номера OEM и пользователя
      mov ah, 30h
      int 21h
      mov si, offset OS_Version_Num + 21
      mov dl, ah
      call BYTE_TO_DEC
      mov al, dl
      add si, 3
      call BYTE_TO_DEC
      ; Выводим на экран версию ОС
      mov dx, offset OS_Version_Num
      call PRINT
      mov al, bh
      call BYTE_TO_HEX
      mov di, offset Num_OEM + 13
      mov [di], al
      mov [di+1], ah
      ; Выводим на экран серийный номер OEM
      mov dx, offset Num_OEM
      call PRINT
      mov al, bl
      call BYTE_TO_HEX
      mov di, offset User_series_num + 29
      mov [di], al
      mov [di+1], ah
      mov ax, cx
      add di, 5
      call WRD_TO_HEX
      ; Выводим на экран серийный номер пользователя
      mov dx, offset User_series_num
      call PRINT
; Выход в DOS
        xor AL,AL
        mov AH,4Ch
        int 21H
END START ; Конец модуля, START - точка входа