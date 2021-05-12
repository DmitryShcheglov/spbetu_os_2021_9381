TESTPC SEGMENT

        ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
        ORG 100H

START:	jmp BEGIN

AvailableMemoryMessage  db 'Available Memory: ', '$'
AvailableMemory         db '             ', 0DH, 0AH, '$'
ExtendedMemoryMessage   db 'Extended Memory: ', '$'
ExtendedMemory          db '             ', 0DH, 0AH, '$'
PSPAddressMessage       db 'PSP Address:      ', 0DH, 0AH, '$'
MCBSizeMessage          db 'Size:      ', 0DH, 0AH, '$'
SCSDMessage             db 'SC/SD: ', 0DH, 0AH, '$'
LineBreak               db 0DH, 0AH, '$'

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
	push cx
	mov ah, al
	call TETR_TO_HEX
	xchg al, ah
	mov cl, 4
	shr al, cl
	call TETR_TO_HEX  
	pop cx          
	ret
BYTE_TO_HEX ENDP

WRD_TO_HEX PROC NEAR
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

PROCESS_NUMBER PROC near
    mov     bx, 10
    xor     cx, cx
loop_bd1:
    div     bx
    push    dx
    inc     cx
    xor     dx, dx
    cmp     ax, 0
    jne     loop_bd1
end_l1:
    pop     dx
    or      dl, 30h
    mov     [di], dl
    inc     di
    loop    end_l1
    
    ret
PROCESS_NUMBER ENDP

PRINT_MESSAGE PROC NEAR
    push ax
    mov ah, 09h
    int 21h
    pop ax
    ret
PRINT_MESSAGE ENDP

AVAILABLE_MEMORY PROC NEAR
    mov ah, 4ah
    mov bx, 0ffffh
    int 21h
    mov ax, bx
    mov bx, 16
    mul bx
    
    call PROCESS_NUMBER
    mov dx, offset AvailableMemory
    call PRINT_MESSAGE
    
    ret
AVAILABLE_MEMORY ENDP

EXTENDED_MEMORY PROC NEAR
    mov AL,30h 
    out 70h,AL
    in AL,71h
    mov BL,AL;
    mov AL,31h 
    out 70h,AL
    in AL,71h
    
    mov bh,al
    mov ax,bx
    
    mov bx,1h
	mul bx

    call PROCESS_NUMBER
    mov dx, offset ExtendedMemory
    call PRINT_MESSAGE
    
    ret
EXTENDED_MEMORY ENDP

MCB_TABLE PROC NEAR
    
    mov ah, 52h
    int 21h
    mov ax, es:[bx-2]
    mov es, ax
    
globalLoop:  
    mov dx, offset LineBreak
    call PRINT_MESSAGE

    mov ax, es:[1]
    mov di, offset PSPAddressMessage + 16
    call WRD_TO_HEX
    mov dx, offset PSPAddressMessage
    call PRINT_MESSAGE
    
    mov ax, es:[3]
    mov di, offset MCBSizeMessage + 6
    mov bx, 16
    mul bx
    call PROCESS_NUMBER
    mov dx, offset MCBSizeMessage
    call PRINT_MESSAGE
    
    mov bx, 8
    mov dx, offset SCSDMessage
    call PRINT_MESSAGE
    mov cx, 7
    
SCSDLoop:
    mov dl, es:[bx]
    mov ah, 02h
    int 21h
    inc bx
    loop SCSDLoop
    
    mov bx, es:[3h]
    mov al, es:[0h]
    cmp al, 5Ah
    je  LoopEnd
    
    mov     ax, es
    inc     ax
    add     ax, bx
    mov     es, ax
    jmp     globalLoop
    
LoopEnd:    
    ret
    
MCB_TABLE ENDP
    
BEGIN:

    mov dx, offset AvailableMemoryMessage
    call PRINT_MESSAGE
    mov di, offset AvailableMemory
    call AVAILABLE_MEMORY
    
    mov dx, offset ExtendedMemoryMessage
    call PRINT_MESSAGE
    mov di, offset ExtendedMemory
    call EXTENDED_MEMORY

    call MCB_TABLE
    
	xor al, al
	mov ax, 4C00h
	int 21h
    
    ret
    
TESTPC ENDS
    END START

END START
