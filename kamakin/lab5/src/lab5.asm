CODE SEGMENT
    ASSUME  CS:CODE, DS:DATA, SS:STACKS

STACKS  SEGMENT STACK
 DW  256 DUP(0)
STACKS  ENDS

DATA SEGMENT
    isLoad db 0
    isUn db 0
    StringInterruptHasLoaded db "The interruption was loaded", 0DH, 0AH, "$"
    StringInterruptAlreadyLoaded db "The interruption is already loaded", 0DH, 0AH, "$"
    StringInterruptUnloaded db "The interruption was unloaded", 0DH, 0AH, "$"
    StringInterruptNotLoaded db "The interruption is not loaded", 0DH, 0AH, "$"
DATA ENDS

interruption PROC FAR
    jmp  Start
    
dataInterruption:
    kValue db 0
    signature DW 6666h
    newStack DW 256 DUP(0)
    ipKeep DW 0
    csKeep DW 0
    pspKeep DW 0
    axKeep DW 0
    ssKeep DW 0
    spKeep DW 0
		
Start:
    mov axKeep, ax
    mov spKeep, sp
    mov ssKeep, SS
    mov ax, seg newStack
    mov SS, ax
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
    je dKey
    cmp al, 23h
    je hKey
    cmp al, 15h
    je yKey
    
    pushf
    call DWord ptr CS:ipKeep
    jmp interruptionEnd

dKey:
    mov kValue, '1'
    jmp nextKey
hKey:
    mov kValue, '2'
    jmp nextKey
yKey:
    mov kValue, '3'

nextKey:
    in al, 61h
    mov ah, al
    or al, 80h
    out 61h, al
    xchg al, al
    out 61h, al
    mov al, 20h
    out 20h, al
  
printKey:
    mov ah, 05h
    mov cl, kValue
    mov ch, 00h
    int 16h
    or 	al, al
    jz 	interruptionEnd
    mov ax, 0040h
    mov es, ax
    mov ax, es:[1ah]
    mov es:[1ch], ax
    jmp printKey

interruptionEnd:
    pop  ds
    pop  es
    pop	 si
    pop  dx
    pop  cx
    pop  bx
    pop	 ax

    mov  sp, spKeep
    mov  ax, ssKeep
    mov  SS, ax
    mov  ax, axKeep

    mov  al, 20h
    out  20h, al
    iret
interruption endp

interruptionUnload PROC
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
    sub si, offset interruption
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
interruptionUnload endp

_end:

isLoaded PROC
    push ax
    push bx
    push si
    
    mov  ah, 35h
    mov  al, 09h
    int  21h
    
    mov  si, offset signature
    sub  si, offset interruption
    mov  ax, es:[bx + si]
    cmp	 ax, signature
    jne  endProc
    mov  isLoad, 1
    
endProc:
    pop  si
    pop  bx
    pop  ax
    ret
isLoaded endp

interruptionLoad PROC
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
    mov ax, seg interruption
    mov dx, offset interruption
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
interruptionLoad  endp

isUnload_  PROC
    push ax
    push es

    mov ax, pspKeep
    mov es, ax
    cmp byte ptr es:[82h], '\'
    jne endUnload
    cmp byte ptr es:[83h], 'u'
    jne endUnload
    cmp byte ptr es:[84h], 'n'
    jne endUnload
    mov isUn, 1
 
endUnload:
    pop es
    pop ax
    ret
isUnload_ endp

output PROC near
    push ax
    mov ah, 09h
    int 21h
    pop ax
ret
output endp

begin PROC
    push ds
    xor ax, ax
    push ax
    mov ax, DATA
    mov ds, ax
    mov pspKeep, es
    
    call isLoaded
    call isUnload_
    cmp isUn, 1
    je unload
    
    mov al, isLoad
    cmp al, 1
    jne load
    mov dx, offset StringInterruptAlreadyLoaded
    call output
    jmp endBegin
    
load:
    mov dx, offset StringInterruptHasLoaded
    call output
    call interruptionLoad
    jmp  endBegin
unload:
    cmp  isLoad, 1
    jne  not_loaded
    mov dx, offset StringInterruptUnloaded
    call output
    call interruptionUnload
    jmp  endBegin
not_loaded:
    mov  dx, offset StringInterruptNotLoaded
    call output
    
endBegin:
    xor al, al
    mov ah, 4ch
    int 21h
begin endp
CODE ENDS
end begin
