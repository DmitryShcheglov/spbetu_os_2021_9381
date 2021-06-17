MAIN SEGMENT
    ASSUME  CS:MAIN, DS:MAIN, ES:NOTHING, SS:NOTHING
    ORG     100H

Start:  
    jmp     Begin

free_mem_mes db 'Free memory: ', '$'    
free_mem db '        bytes', 0DH, 0AH, '$'
extended_mem_mes db 'Extended memory: ', '$'
extended_mem db '       bytes', 0DH, 0AH, '$'
mcb_table db 'Memory Control Block list: ', 0DH, 0AH, '$'
mcb_type db 'MCB type:   h    ', '$'
mcb_adress db 'PSP address:     h    ', '$'
mcb_size db 'Size:        bytes    ', '$'
some_mes db 0DH, 0AH, '$'    

TETR_TO_HEX PROC NEAR
    and     al, 0Fh
    cmp     al, 09
    jbe     Next
    add     al, 07
Next:
    add     al, 30h
    ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC NEAR
    push    cx
    mov     ah, al
    call    TETR_TO_HEX
    xchg    al, ah
    mov     cl, 4
    shr     al, cl
    call    TETR_TO_HEX
    pop     cx
    ret
BYTE_TO_HEX ENDP

WRD_TO_HEX PROC near
    push    bx
    mov     bh, ah
    call    BYTE_TO_HEX
    mov     [di], ah
    dec     di
    mov     [di], al
    dec     di
    mov     al, bh
    call    BYTE_TO_HEX
    mov     [di], ah
    dec     di
    mov     [di], al
    pop     bx
    ret
WRD_TO_HEX ENDP

BYTE_TO_DEC PROC near
    push    cx
    push    dx
    xor     ah, ah
    xor     dx, dx
    mov     cx, 10
Loop_bd:
    div     cx
    or      dl, 30h
    mov     [si], dl
    dec     si
    xor     dx, dx
    cmp     ax, 10
    jae     Loop_bd
    cmp     al, 00h
    je      End_l
    or      al, 30h
    mov     [si], al
End_l:  
    pop     dx
    pop     cx
    ret
BYTE_TO_DEC ENDP

PRINT_MES  PROC near
    push    ax
    mov     ah, 9
    int     21h
    pop     ax
    ret
PRINT_MES ENDP

HEX_TO_DEC PROC near
    mov     bx, 0Ah
    xor     cx, cx
	
byte_step:
    div     bx
    push    dx
    inc     cx
    xor     dx, dx
    cmp     ax, 0
    jne     byte_step
	
add_symbol:
    pop     dx
    or      dl, 30h
	
    mov     [di], dl
    inc     di
    loop    add_symbol
    ret
HEX_TO_DEC ENDP

GET_FREE_MEM PROC near
    mov     ah, 4ah
    mov     bx, 0ffffh
    int     21h
    mov     ax, bx
    mov     bx, 16
    mul     bx
    call    HEX_TO_DEC 
    ret
GET_FREE_MEM ENDP

GET_EXTENDED_MEM PROC near
    mov     al, 30h
    out     70h, al
    in      al, 71h
    mov     al, 31h
    out     70h, al
    in      al, 71h
    mov     bh, al
    mov     ax, bx
    
    mov     bx, 1h
    mul     bx
    call    HEX_TO_DEC
    ret
GET_EXTENDED_MEM ENDP

GET_MCB PROC near
    mov     ah, 52h
    int     21h
    mov     ax, es:[bx-2]
    mov     es, ax
    
mcb:
    mov 	al, es:[0]
    call 	BYTE_TO_HEX
    mov		di, offset mcb_type
    add     di, 10
    mov 	[di], ax      
    mov		dx, offset mcb_type
    call 	PRINT_MES

    mov     ax, es:[1]
    mov     di, offset mcb_adress + 16
    call    WRD_TO_HEX
    mov     dx, offset mcb_adress
    call    PRINT_MES
                
    mov     ax, es:[3]
    mov     di, offset mcb_size + 6
    mov     bx, 16
    mul     bx
    call    HEX_TO_DEC
    mov     dx, offset mcb_size
    call    PRINT_MES
    
    mov     bx, 8
    mov cx, 7

scsd:
    mov     dl, es:[bx]
    mov     ah, 02h
    int     21h
    inc     bx
    loop    scsd
    
    mov     dx, offset some_mes
    call    PRINT_MES
    
    mov     bx, es:[3h]
    mov     al, es:[0h]
    cmp     al, 5Ah
    je      end_point
    
    mov     ax, es
    inc     ax
    add     ax, bx
    mov     es, ax
    jmp     mcb
    
end_point:
    ret
GET_MCB ENDP

Begin:
    mov     dx, offset free_mem_mes
    call    PRINT_MES   
    mov     di, offset free_mem
    call    GET_FREE_MEM
    
    mov     dx, offset free_mem
    call    PRINT_MES
    mov     dx, offset extended_mem_mes
    call    PRINT_MES
    
    mov     di, offset extended_mem
    call    GET_EXTENDED_MEM
    mov     dx, offset extended_mem
    call    PRINT_MES
    
    mov     dx, offset mcb_table
    call    PRINT_MES
    call    GET_MCB
    
    xor     al, al
    mov     ah, 4ch
    int     21h
MAIN ENDS
    END     Start
