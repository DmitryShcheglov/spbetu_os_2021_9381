CODE      SEGMENT
          ASSUME CS:CODE, DS:DATA, SS:ASTACK
          
INTERRUPT PROC far
    jmp startInterrupt
   
    psp dw 0
    keep_IP dw 0
    keep_CS dw 0
    interrupt_id dw 8f17h
   
    CounterMessage db 'Own interrupt number: 0000$'
                  
	keep_SS dw 0
	keep_SP dw 0
	keep_AX dw 0
	interruptStack dw 32 dup (0)
	endOfStack dw 0
   
startInterrupt:
   mov keep_SS, ss
   mov keep_SP, sp
   mov keep_AX, ax

   mov ax, cs
   mov ss, ax
   mov sp, offset endOfStack

   push bx
   push cx
   push dx
   
	mov ah, 3h
	mov bh, 0h
	int 10h
	push dx
   
	mov ah, 02h
	mov bh, 0h
   mov dh, 02h
   mov dl, 05h
	int 10h
   
   push si
	push cx
	push ds
   push bp
   
	mov ax, SEG CounterMessage
	mov ds, ax
	mov si, offset CounterMessage
	add si, 22

   mov cx, 4  
interruptLoop:
   mov bp, cx
   mov ah, [si+bp]
	inc ah
	mov [si+bp], ah
	cmp ah, 3Ah
	jne number
	mov ah, 30h
	mov [si+bp], ah

   loop interruptLoop 
    
number:
   pop bp
   
   pop ds
   pop cx
   pop si
   
	push es
	push bp
   
	mov ax, SEG CounterMessage
	mov es, ax
	mov ax, offset CounterMessage
	mov bp, ax
	mov ah, 13h
	mov al, 1h
	mov bl, 16h
	mov cx, 27
	mov bh, 0
	int 10h
   
	pop bp
	pop es
   
	pop dx
	mov ah, 02h
	mov bh, 0h
	int 10h

	pop dx
	pop cx
	pop bx
   
	mov ax, keep_SS
	mov ss, ax
	mov ax, keep_AX
	mov sp, keep_SP

   iret
endInterrupt:
INTERRUPT ENDP          


PRINT PROC near
   push ax
   mov ah, 09h
   int 21h
   pop ax
   ret
PRINT ENDP


FLOAD PROC near
   push ax
   
   mov psp, es
   mov al, es:[81h+1]
   cmp al, '/'
   jne floadEnd
   mov al, es:[81h+2]
   cmp al, 'u'
   jne floadEnd
   mov al, es:[81h+3]
   cmp al, 'n'
   jne floadEnd
   mov flag, 1h
  
floadEnd:
   pop ax
   ret
FLOAD ENDP


IS_SET PROC near
   push ax
   push si
   
   mov ah, 35h
   mov al, 1Ch
   int 21h
   mov si, offset interrupt_id
   sub si, offset INTERRUPT
   mov dx, es:[bx+si]
   cmp dx, 8f17h
   jne isSetEnd
   mov loadFlag, 1h
isSetEnd:   
   pop si
   pop ax
   ret
IS_SET ENDP


SET_INTERRUPT PROC near
   push ax
   push dx
   
   call IS_SET
   cmp loadFlag, 1h
   je loadAlready
   jmp loadStart
   
loadAlready:
   mov dx, offset messageAlreadySet
   call PRINT
   jmp loadEnd
  
loadStart:
   mov ah, 35h
	mov al, 1Ch
	int 21h 
	mov keep_CS, es
	mov keep_IP, bx
   
   push ds
   lea dx, INTERRUPT
   mov ax, seg INTERRUPT
   mov ds, ax
   mov ah, 25h
   mov al, 1Ch
   int 21h
   pop ds
   mov dx, offset messageSetDone
   call PRINT
   
   mov dx, offset endInterrupt
   mov cl, 4h
   shr dx, cl
   inc dx
   mov ax, cs
   sub ax, psp
   add dx, ax
   xor ax, ax
   mov ah, 31h
   int 21h
     
loadEnd:  
   pop dx
   pop ax
   ret
SET_INTERRUPT ENDP


UNSET_INTERRUPT PROC near
   push ax
   push si
   
   call IS_SET
   cmp loadFlag, 1h
   jne errorUnset
   jmp startUnset
   
errorUnset:
   mov dx, offset messageNotSet
   call PRINT
   jmp endUnset
   
startUnset:
   cli 
   push ds
   mov ah, 35h
   mov al, 1Ch
   int 21h

   mov si, offset keep_IP
   sub si, offset INTERRUPT
   mov dx, es:[bx+si]
   mov ax, es:[bx+si+2]
   MOV ds, ax
   MOV ah, 25H
   MOV al, 1CH
   int 21H
   pop ds
   
   mov ax, es:[bx+si-2]
   mov es, ax
   push es
   
   mov ax, es:[2ch]
   mov es, ax
   mov ah, 49h
   int 21h
   
   pop es
   mov ah,49h
   int 21h
   sti
   
   mov dx, offset messageIsUnset
   call PRINT
endUnset:   
   pop si
   pop ax
   ret
UNSET_INTERRUPT ENDP

MAIN      PROC  FAR
   push  ds       
   mov   ax, 0    
   push  ax       
   mov   ax, DATA             
   mov   ds, ax

   call FLOAD
   cmp flag, 1h
   je callUnset
   call SET_INTERRUPT
   jmp _end_
   
callUnset:
   call UNSET_INTERRUPT
   
_end_:  
   ret   
MAIN      ENDP
CODE      ENDS

ASTACK    SEGMENT  STACK
   DW 64 DUP(?)   
ASTACK    ENDS

DATA      SEGMENT
   flag db 0
   loadFlag db 0

   messageNotSet  DB 'Обработчик прерывания не установлен', 0AH, 0DH,'$'
   messageAlreadySet  DB 'Обработчик прерывания уже установлен', 0AH, 0DH,'$'
   messageSetDone  DB 'Обработчик прерывания установлен', 0AH, 0DH,'$'
   messageIsUnset  DB 'Обработчик прерывания сброшен', 0AH, 0DH,'$'
DATA      ENDS
          END Main