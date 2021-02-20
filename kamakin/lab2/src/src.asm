ETU SEGMENT
    ASSUME  CS:ETU, DS:ETU, ES:NOTHING, SS:NOTHING
    ORG     100H

Start:  
    jmp     Begin
    
StringMemoryAddress db 'Segment address of the invalid memory:     ', 0DH, 0AH, '$' 
StringEnviromentAddress db 'Segment address of the enviroment:          ', 0DH, 0AH, '$'
StringArgumentsMessage db 'Command line arguments:  ', '$'
StringEnviromentAreaMessage db 'Content of the enviroment area: ', 0DH, 0AH, '$'
StringModulePathMessage db 'Path of the module: ', '$'
StringModulePath db 128 DUP('$')
StringArguments db 128 DUP('$')
StringEnviromentArea db 128 DUP('$')
    
; converting a tetrad from AL to hex (result in AL)
TETR_TO_HEX PROC NEAR
    and     al, 0Fh
    cmp	    al, 09
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

; writes segment address of the invalid memory to the string pointed to by DI
INVALID_MEMORY_ADDRESS PROC near
    mov     ax, ds:[02h]
    call    WRD_TO_HEX
    ret
INVALID_MEMORY_ADDRESS ENDP

; writes segment address of the enviroment to the string pointed to by DI
ENVIROMENT_ADDRESS PROC near
    mov     ax, ds:[2Ch]
    call    WRD_TO_HEX
    ret
ENVIROMENT_ADDRESS ENDP

; writes command-line arguments to the string pointed to by DI
ARGUMENTS PROC near
    mov     cl, ds:[80h]
    cmp     cl, 0h
    je      No_arguments
    xor     bx, bx
Load_arguments:
    mov     al, ds:[81h+bx]
    mov     [di+bx], al
    inc     bx
    loop    Load_arguments
No_arguments:
    mov     byte ptr [di+bx], 0Dh
    mov     byte ptr [di+bx+1], 0Ah
    mov     byte ptr [di+bx+2], '$'
    ret
ARGUMENTS ENDP

; writes the enviroment content to the string pointed to by DI, moves SI to the path of the loaded module (can be used by MODULE_PATH)
ENVIROMENT PROC near
    mov     ax, ds:[2Ch]
    mov     ds, ax
    xor     si, si
Enviroment_strings:
    lodsb
    cmp     al, 0h
    je      Enviroment_strings_end
Enviroment_strings_start:    
    stosb
    jmp     Enviroment_strings
Enviroment_strings_end:
    mov     al, 0Ah
    stosb
    lodsb
    cmp     al, 0h
    jne     Enviroment_strings_start
    mov byte ptr es:[di], 0Dh
	mov byte ptr es:[di+1], '$'
    add     si, 2h
	mov     bx, ds
	mov     ax, es
	mov     ds, ax
    ret
ENVIROMENT ENDP

; writes the path of the loaded module to the string pointed to by DI
MODULE_PATH PROC near
    mov     ax, ds:[2Ch]
    mov     ds, ax
Path_loop:
    lodsb
    cmp     al, 0h
    je     Path_loop_end
    stosb
    jmp     Path_loop
Path_loop_end:    
    mov byte ptr es:[di], 0Dh
	mov byte ptr es:[di+1], '$'
	mov     bx, ds
	mov     ax, es
	mov     ds, ax
    ret
MODULE_PATH ENDP
    
Begin:
    mov     di, offset StringMemoryAddress + 42
    call    INVALID_MEMORY_ADDRESS
    mov     dx, offset StringMemoryAddress
    call    OUTPUT
    
    mov     di, offset StringEnviromentAddress + 38
    call    ENVIROMENT_ADDRESS
    mov     dx, offset StringEnviromentAddress
    call    OUTPUT
    
    mov     di, offset StringArguments
    call    ARGUMENTS
    mov     dx, offset StringArgumentsMessage
    call    OUTPUT
    mov     dx, offset StringArguments
    call    OUTPUT

    mov     dx, offset StringEnviromentAreaMessage
    call    OUTPUT
    mov     di, offset StringEnviromentArea
    call    ENVIROMENT
    mov     dx, offset StringEnviromentArea
    call    OUTPUT
    
    mov     dx, offset StringModulePathMessage
    call    OUTPUT
    mov     di, offset StringModulePath
    call    MODULE_PATH
    mov     dx, offset StringModulePath
    call    OUTPUT
    
    xor     al, al
    mov     ah, 4Ch
    int     21h
ETU ENDS
    END     Start
