ETU SEGMENT
    ASSUME  CS:ETU, DS:ETU, ES:NOTHING, SS:NOTHING
    ORG     100H

Start:  
    jmp     Begin

StringMemoryAvailableMessage db 'Available memory: ', '$'    
StringMemoryAvailable db '        bytes', 0DH, 0AH, '$'
StringMemoryExtendedMessage db 'Extended memory: ', '$'
StringMemoryExtended db '       bytes', 0DH, 0AH, '$'
StringMCBTable db 'MCB table: ', 0DH, 0AH, '$'
StringMCBPSPAddress db 'PSP address:      ', '$'
StringMCBSize db 'Size:         ', '$'
StringMCBSCSD db 'SC/SD: ', '$'
StringEmpty db 0DH, 0AH, '$'    
StringMemorySuccess db 'Memory request succeeded', 0DH, 0AH, '$'
StringMemoryFail db 'Memory request failed', 0DH, 0AH, '$'
    
; converting a tetrad from AL to hex (result in AL)
TETR_TO_HEX PROC NEAR
    and     al, 0Fh
    cmp     al, 09
    jbe     Next
    add     al, 07
Next:
    add     al, 30h
    ret
TETR_TO_HEX ENDP

; converting a byte from AL to hex (result in AL and AH)
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

; converting a word from AX to hex (result in 4 symbols pointed by DI)
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

; converting a byte from SI to dec
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

; outputs a string from DX
OUTPUT  PROC near
    push    ax
    mov     ah, 9
    int     21h
    pop     ax
    ret
OUTPUT ENDP

; translates hex from ax to di
HEX_TO_BYTE PROC near
    mov     bx, 0Ah
    xor     cx, cx
	
To_byte:
    div     bx
    push    dx
    inc     cx
    xor     dx, dx
    cmp     ax, 0
    jne     To_byte
	
Push_symbol:
    pop     dx
    or      dl, 30h
	
    mov     [di], dl
    inc     di
    loop    Push_symbol
    ret
HEX_TO_BYTE ENDP

; writes available memory to di
MEM_AVAILABLE PROC near
    mov     ah, 4ah
    mov     bx, 0ffffh
    int     21h
    mov     ax, bx
    mov     bx, 16
    mul     bx
    call    HEX_TO_BYTE 
    ret
MEM_AVAILABLE ENDP

; writes extended memory to di
MEM_EXTENDED PROC near
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
    call    HEX_TO_BYTE
    ret
MEM_EXTENDED ENDP

; outputs mcb table 
OUTPUT_MCB PROC near
    mov     ah, 52h
    int     21h
    mov     ax, es:[bx-2]
    mov     es, ax
    
MCB_loop:
;   PSP address output
    mov     ax, es:[1]
    mov     di, offset StringMCBPSPAddress + 16
    call    WRD_TO_HEX
    mov     dx, offset StringMCBPSPAddress
    call    OUTPUT
        
;   Size output        
    mov     ax, es:[3]
    mov     di, offset StringMCBSize + 6
    mov     bx, 16
    mul     bx
    call    HEX_TO_BYTE
    mov     dx, offset StringMCBSize
    call    OUTPUT
    
;   SC/SD output
    mov     bx, 8
    mov     dx, offset StringMCBSCSD
    call    OUTPUT
    mov cx, 7

SCSD_loop:
    mov     dl, es:[bx]
    mov     ah, 02h
    int     21h
    inc     bx
    loop    SCSD_loop
    
    mov     dx, offset StringEmpty
    call    OUTPUT
    
    mov     bx, es:[3h]
    mov     al, es:[0h]
    cmp     al, 5Ah
    je      MCB_end
    
    mov     ax, es
    inc     ax
    add     ax, bx
    mov     es, ax
    jmp     MCB_loop
    
MCB_end:
    ret
OUTPUT_MCB ENDP

; free unusable memory
MEM_FREE PROC near
    mov     ax, cs
    mov     es, ax
    mov     bx, offset ETU_ends
    mov     ax, es
    mov     bx, ax
    mov     ah, 4ah
    int     21h
    ret
MEM_FREE ENDP

; request for 64kb
MEM_REQUEST PROC near
    mov     bx, 1000h ; = 64kb
    mov     ah, 48h
    int     21h
    
    jb      Fail ; cf = 1
    jmp     Success
Fail:   
    mov     dx, offset StringMemoryFail 
    call    OUTPUT
    jmp     Request_end
Success:
    mov     dx, offset StringMemorySuccess
    call    OUTPUT
Request_end:    
    ret
MEM_REQUEST ENDP

Begin:
    mov     dx, offset StringMemoryAvailableMessage
    call    OUTPUT
    
    mov     di, offset StringMemoryAvailable
    call    MEM_AVAILABLE
    
    mov     dx, offset StringMemoryAvailable
    call    OUTPUT
    
    mov     dx, offset StringMemoryExtendedMessage
    call    OUTPUT
    
    mov     di, offset StringMemoryExtended
    call    MEM_EXTENDED
    
    mov     dx, offset StringMemoryExtended
    call    OUTPUT
    
    call    MEM_FREE
    call    MEM_REQUEST
    
    mov     dx, offset StringMCBTable
    call    OUTPUT
    
    call    OUTPUT_MCB
    
    xor     al, al
    mov     ah, 4ch
    int     21h
ETU_ends:    
ETU ENDS
    END     Start
