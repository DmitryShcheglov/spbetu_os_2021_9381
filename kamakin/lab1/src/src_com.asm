PCINFO  SEGMENT
        ASSUME  CS:PCINFO, DS:PCINFO, ES:NOTHING, SS:NOTHING
        ORG     100H

Start:  
    jmp     Begin

StringType       db      'Machine type: ', '$'
StringSystemVer  db      'System version:  .  ', 0DH, 0AH, '$'
StringOEM        db      'OEM:  ', 0DH, 0AH, '$'
StringUser       db      'User serial number:       ', 0DH, 0AH, '$'

TypeAT           db      'AT', 0DH, 0AH, '$'
TypePC           db      'PC', 0DH, 0AH,'$'
TypeXT           db      'PC/XT', 0DH, 0AH, '$'
TypePS2_30       db      'PS2 model 30', 0DH, 0AH, '$'
TypePS2_50_60    db      'PS2 model 50 or 60', 0DH, 0AH, '$'
TypePS2_80       db      'PS2 model 80', 0DH, 0AH, '$'
TypePCjr         db      'PCjr', 0DH, 0AH, '$'
TypePCC          db      'PC Convertible', 0DH, 0AH, '$'
TypeUnkown       db      '    (unkown type)', 0DH, 0AH, '$'


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

OUTPUT  PROC near
    push    ax
    mov     ah, 9
    int     21h
    pop     ax
    ret
OUTPUT ENDP

Begin:
;   30h interrupt (obtain the DOS version)
    mov     ah, 30h
    int     21h
    
;   write system version in string (currently in al and ah)   
    mov     dh, ah ; saving ah in dh as byte_to_dec rewrites it
    mov     di, offset StringSystemVer
    call    BYTE_TO_DEC
    lodsw   ; load ah from si (byte_to_dec writes result in si)
    mov     [di+16], ah
                
    mov     al, dh
    call    BYTE_TO_DEC
    lodsw
    mov     [di+18], ah
    
;   write OEM version in string (currently in bh) using byte_to_hex   
    mov     al, bh
    call    BYTE_TO_HEX
    mov     di, offset StringOEM
    mov     [di+5], al
    mov     [di+6], ah
        
;   write user serial number in string (currently in bl) using byte_to_hext (converys byte to hex and writes in al and ah)        
    mov     di, offset StringUser
    mov     al, bl
    call    BYTE_TO_HEX
    mov     [di+21], al
    mov     [di+22], ah
    
    mov     ax, cx
    add     di, 26
    call    WRD_TO_HEX
  
    mov     dx, offset StringType
    call    OUTPUT 
 
;   get IBM PC type from penultimate byte of ROM BIOS (0F000H) 
    mov     ax, 0F000H
    mov     es, ax
    mov     al, es:[0FFFEH]
    
;   convert type to string    
    cmp     al, 0FFh
    je      SetPC
    cmp     al, 0FEh
    je      SetXT
    cmp     al, 0FBh
    je      SetXT
    cmp     al, 0FCh
    je      SetAT
    cmp     al, 0FAh
    je      SetPS2_50
    cmp     al, 0FCh
    je      SetPS2_50_60
    cmp     al, 0F8h
    je      SetPS2_80
    cmp     al, 0FDh
    je      SetPCjr
    cmp     al, 0F9h
    je      SetPCC
        
    jmp     SetUnkown
        
SetPC:
    mov     dx, offset TypePC
    jmp     ExitP
SetAT:
    mov     dx, offset TypeAT
    jmp     ExitP
SetXT:
    mov     dx, offset TypeXT
    jmp     ExitP
SetPS2_50:
    mov     dx, offset TypePS2_30
    jmp     ExitP
SetPS2_50_60:
    mov     dx, offset TypePS2_50_60
    jmp     ExitP
SetPS2_80:
    mov     dx,offset TypePS2_80
    jmp     ExitP
SetPCjr:
    mov     dx,offset TypePCjr
    jmp     ExitP
SetPCC:
    mov     dx, offset TypePCC
    jmp     Output
    
SetUnkown:
    call    BYTE_TO_HEX
    mov     di, offset TypeUnkown
    mov     [di], al
    mov     [di+1], ah
    mov     dx, offset TypeUnkown

;   output all strings and exit the program    
ExitP:
    call    OUTPUT
        
    mov     dx, offset StringSystemVer
    call    OUTPUT
    
    mov     dx, offset StringOEM
    call    OUTPUT
        
    mov     dx, offset StringUser
    call    OUTPUT
    
    xor     al, al
    mov     ah, 4Ch
    int     21h
PCINFO  ENDS
    END     Start
