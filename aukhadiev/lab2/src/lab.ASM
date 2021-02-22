TESTPC SEGMENT

        ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
        ORG 100H

START:	jmp BEGIN

SegmentAdressUnavailableMemory db 'Segment Adress of Unavailable Memory:     ', 0DH, 0AH, '$'
SegmentAdressEnvironment       db 'Segment Adress of Environment:     ', 0DH, 0AH, '$'
CommandArguments               db 'Command arguments:', '$'
EnvironmentArea                db 'Environment Area:', 0DH, 0AH, '$'
Path                           db 'Path:', '$'
ArgumentsString                db 128 dup ('$')
EnvironmentAreaString          db 128 dup ('$')
PathString                     db 128 dup ('$')

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

PRINT_MESSAGE PROC NEAR
    push ax
    mov ah, 09h
    int 21h
    pop ax
    ret
PRINT_MESSAGE ENDP
    
BEGIN:
    lea di, SegmentAdressUnavailableMemory + 41
    mov ax, ds:[02h]
    call WRD_TO_HEX
    mov dx, offset SegmentAdressUnavailableMemory
    call PRINT_MESSAGE
    
    lea di, SegmentAdressEnvironment + 34
    mov ax, ds:[2Ch]
    call WRD_TO_HEX
    mov dx, offset SegmentAdressEnvironment
    call PRINT_MESSAGE
    
    mov cl, ds:[80h]    
    mov si, 0
    cmp cl, 0
    je EndArgumentLoop
ArgumentLoop:
    mov al, ds:[81h + si]
    mov ArgumentsString[si], al
    inc si
    loop ArgumentLoop
EndArgumentLoop:
    mov dx, offset CommandArguments
    call PRINT_MESSAGE
    mov al, 10
    mov ArgumentsString[si], al
    mov dx, offset ArgumentsString
    call PRINT_MESSAGE
 
    mov ax, ds:[2Ch]
    mov ds, ax
    mov di, offset EnvironmentAreaString
    mov si, 0
loopEnvironmentArea:
    lodsb
    cmp al, 0
    je addLineBreak
    stosb
    jmp loopEnvironmentArea  
addLineBreak:
    mov al, 10
    stosb
    lodsb
    cmp al, 0
    je endLoop
    stosb
    jmp loopEnvironmentArea
endLoop:
    mov al, 0Dh
    stosb
    mov al, 36
    stosb
    push ds
    mov ax, es
    mov ds, ax
   
    mov dx, offset EnvironmentArea
    call PRINT_MESSAGE
    mov dx, offset EnvironmentAreaString
    call PRINT_MESSAGE
    
    mov di, offset PathString
    pop ds
    lodsb
    lodsb
pathLoop:
    lodsb
    cmp al, 0
    je endPathLoop
    stosb
    jmp pathLoop
endPathLoop:
    mov al, 0Ah
    stosb
    mov al, 0Dh
    stosb
    mov al, 36
    stosb
    mov ax, es
    mov ds, ax
    
    mov dx, offset Path
    call PRINT_MESSAGE
    mov dx, offset PathString
    call PRINT_MESSAGE
	
	xor al, al
	mov ax, 4C00h
	int 21h
    
    ret
    
TESTPC ENDS
    END START

END START
