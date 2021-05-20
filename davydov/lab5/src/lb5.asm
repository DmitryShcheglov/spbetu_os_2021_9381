CODE SEGMENT
	ASSUME  CS:CODE, DS:DATA, SS:LAB_STACK

LAB_STACK  SEGMENT STACK
	DW  256 DUP(0)
LAB_STACK  ENDS

DATA SEGMENT
    isLoad db 0
    isUn db 0
    interruptLoad db "The interruption was loaded", 0DH, 0AH, "$"
    interruptLoaded db "The interruption is already loaded", 0DH, 0AH, "$"
    interruptUnloaded db "The interruption was unloaded", 0DH, 0AH, "$"
    interruptNotUnloaded db "The interruption is not loaded", 0DH, 0AH, "$"
DATA ENDS

INTERRUPT PROC FAR
    jmp  START
    
DATA_KEEP:
    kValue db 0
    signature DW 6666h
    newStack DW 256 DUP(0)
    ipKeep DW 0
    csKeep DW 0
    pspKeep DW 0
    axKeep DW 0
    ssKeep DW 0
    spKeep DW 0
		
START:
    mov axKeep, ax
    mov spKeep, sp
    mov ssKeep, ss
    mov ax, seg newStack
    mov ss, ax
    mov ax, offset newStack
    add ax, 256
    mov sp, ax	

    push ax
    push bx
    push cx
    push dx
    push si
    push es
    push ds
    mov ax, seg kValue
    mov ds, ax
    
    in al, 60h
    cmp al, 20h
    je KEY_D
    cmp al, 2Ch
    je KEY_Z
    cmp al, 13h
    je KEY_R
    
    pushf
    call DWord ptr CS:ipKeep
    jmp INTERRUPTION_END

KEY_D:
    mov kValue, '9'
    jmp NEXT_KEY
KEY_Z:
    mov kValue, '8'
    jmp NEXT_KEY
	
KEY_R:
    mov kValue, '7'

NEXT_KEY:
    in al, 61h
    mov ah, al
    or al, 80h
    out 61h, al
    xchg al, al
    out 61h, al
    mov al, 20h
    out 20h, al
  
PRINT_KEY:
    mov ah, 05h
    mov cl, kValue
    mov ch, 00h
    int 16h
    or 	al, al
    jz 	INTERRUPTION_END
    mov ax, 0040h
    mov es, ax
    mov ax, es:[1ah]
    mov es:[1ch], ax
    jmp PRINT_KEY

INTERRUPTION_END:
    pop  ds
    pop  es
    pop	 si
    pop  dx
    pop  cx
    pop  bx
    pop	 ax

    mov  sp, spKeep
    mov  ax, ssKeep
    mov  ss, ax
    mov  ax, axKeep

    mov  al, 20h
    out  20h, al
    iret
	
INTERRUPT endp

INTERRUPTION_UNLOAD PROC
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
    mov si, offset ipKeep
    sub si, offset INTERRUPT
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
INTERRUPTION_UNLOAD endp

_end:

IS_LOADED PROC
    push ax
    push bx
    push si
    
    mov  ah, 35h
    mov  al, 09h
    int  21h
    
    mov  si, offset signature
    sub  si, offset INTERRUPT
    mov  ax, es:[bx + si]
    cmp	 ax, signature
    jne  END_CHECK
    mov  isLoad, 1
    
END_CHECK:
    pop  si
    pop  bx
    pop  ax
    ret
	
IS_LOADED endp

INTERRUPTION_LOAD PROC
    push ax
    push bx
    push cx
    push dx
    push es
    push ds

    mov ah, 35h
    mov al, 09h
    int 21h
    mov csKeep, es
    mov ipKeep, bx
    mov ax, seg INTERRUPT
    mov dx, offset INTERRUPT
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
INTERRUPTION_LOAD  endp

IS_UNLOAD  PROC
    push ax
    push es

    mov ax, pspKeep
    mov es, ax
    cmp byte ptr es:[82h], '/'
    jne END_UNLOAD
    cmp byte ptr es:[83h], 'u'
    jne END_UNLOAD
    cmp byte ptr es:[84h], 'n'
    jne END_UNLOAD
    mov isUn, 1
 
END_UNLOAD:
    pop es
    pop ax
    ret
	
IS_UNLOAD endp

OUTPUT PROC near
    push ax
    mov ah, 09h
    int 21h
    pop ax
ret
OUTPUT endp

BEGIN PROC
    push ds
    xor ax, ax
    push ax
    mov ax, DATA
    mov ds, ax
    mov pspKeep, es
    
    call IS_LOADED
    call IS_UNLOAD
    cmp isUn, 1
    je unload
    
    mov al, isLoad
    cmp al, 1
    jne LOAD
    mov dx, offset interruptLoaded
    call OUTPUT
    jmp END_BEGIN
    
LOAD:
    mov dx, offset interruptLoad
    call OUTPUT
    call INTERRUPTION_LOAD
    jmp  END_BEGIN
	
UNLOAD:
    cmp  isLoad, 1
    jne  not_loaded
    mov dx, offset interruptUnloaded
    call OUTPUT
    call INTERRUPTION_UNLOAD
    jmp  END_BEGIN
	
NOT_LOADED:
    mov  dx, offset interruptNotUnloaded
    call OUTPUT
    
END_BEGIN:
    xor al, al
    mov ah, 4ch
    int 21h
	
BEGIN endp
CODE ENDS
end BEGIN