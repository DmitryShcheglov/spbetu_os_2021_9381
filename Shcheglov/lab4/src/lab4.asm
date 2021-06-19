CODE SEGMENT
   ASSUME CS:CODE, DS:DATA, SS:ASTACK
;==============================================
ROUT PROC far
    jmp start_interrupt

    PSP dw ?
    KEEP_IP dw 0
    KEEP_CS dw 0
    INTERRUPT_ID dw 8F17h
   
    STR_COUNTER db 'Interrupts: 0000'
                  
	KEEP_SS dw ?
	KEEP_SP dw ?
	KEEP_AX dw ?
	INTERRUPT_STACK dw 32 dup (?)
	END_IT_STACK dw ?
   
start_interrupt:
    mov KEEP_SS, SS
    mov KEEP_SP, SP
    mov KEEP_AX, AX

    mov AX, CS
    mov SS, AX
    mov SP, offset END_IT_STACK

    push BX
    push CX
    push DX
   
	mov AH, 3h
	mov BH, 0h
	int 10h
	push DX
   
	mov AH, 02h
	mov BH, 0h
    mov DH, 02h
    mov DL, 05h
	int 10h
   
    push si
	push cx
	push ds
    push bp
   
	mov AX, seg STR_COUNTER
	mov DS, AX
	mov SI, offset STR_COUNTER
	add SI, 11

    mov CX, 4  
interrupt_loop:
    mov BP, CX
    mov AH, [SI+BP]
	inc AH
	mov [SI+BP], AH
	cmp AH, 3Ah
	jne number
	mov AH, 30h
	mov [SI+BP], AH
    loop interrupt_loop 
    
number:
    pop BP
   
    pop DS
    pop CX
    pop SI
   
	push ES
	push BP
   
	mov AX, seg STR_COUNTER
	mov ES, AX
	mov AX, offset STR_COUNTER
	mov BP, ax
	mov AH, 13h
	mov AL, 00h
	mov CX, 16
	mov BH, 0
	int 10h
   
	pop BP
	pop ES
   
	pop DX
	mov AH, 02h
	mov BH, 0h
	int 10h

	pop DX
	pop CX
	pop BX
   
	mov AX, KEEP_SS
	mov SS, AX
	mov AX, KEEP_AX
	mov SP, KEEP_SP

    mov AL, 20H
    out 20H, AL
    iret
rout_end:
ROUT ENDP          
;==============================================
OUTPUTTING_STRING_TO_CONSOLE PROC near
	push AX
	mov AH,09h
	int 21h
	pop AX
	ret
OUTPUTTING_STRING_TO_CONSOLE ENDP
;==============================================
LOAD_FLAG PROC near
    push AX
   
    mov PSP, ES
    mov AL, ES:[81h+1]
    cmp AL,'/'
    jne load_flag_end
    mov AL,ES:[81h+2]
    cmp AL, 'u'
    jne load_flag_end
    mov AL, ES:[81h+3]
    cmp AL, 'n'
    jne load_flag_end
    mov flag, 1h
  
load_flag_end:
    pop AX
    ret
LOAD_FLAG ENDP
;==============================================
IS_LOAD PROC near
    push AX
    push SI
   
    mov AH, 35h
    mov AL, 1Ch
    int 21h
    mov SI, offset INTERRUPT_ID
    sub SI, offset ROUT
    mov DX, ES:[BX+SI]
    cmp DX, 8f17h
    jne is_load_end
    mov flag_load, 1h
is_load_end:   
    pop SI
    pop AX
    ret
IS_LOAD ENDP
;==============================================
LOAD_INTERRUPT PROC near
    push AX
    push DX
   
    call IS_LOAD
    cmp flag_load, 1h
    je already_load
    jmp start_load
   
already_load:
    mov DX, offset STRING_INTERRUPT_IS_ALREADY_LOADED
    call OUTPUTTING_STRING_TO_CONSOLE
    jmp end_load
  
start_load:
    mov AH, 35h
	mov AL, 1Ch
	int 21h 
	mov KEEP_CS, ES
	mov KEEP_IP, BX
   
    push DS
    lea DX, ROUT
    mov AX, seg ROUT
    mov DS, AX
    mov AH, 25h
    mov AL, 1Ch
    int 21h
    pop DS
    mov DX, offset STRING_LOADING_INTER
    call OUTPUTTING_STRING_TO_CONSOLE
   
    mov dx, offset rout_end
    mov CL, 4h
    shr DX, CL
    inc DX
    mov AX, CS
    sub AX, PSP
    add DX, AX
    xor AX, AX
    mov AH,31h
    int 21h
     
end_load:  
    pop DX
	pop AX
    ret
LOAD_INTERRUPT ENDP
;==============================================
UNLOAD_INTERRUPT PROC near
   push AX
   push SI
   
   call IS_LOAD
   cmp flag_load, 1h
   jne cant_unload
   jmp start_unload
   
cant_unload:
   mov DX, offset WAS_NO_INTERRUPT_FOR_UNLOADING
   call OUTPUTTING_STRING_TO_CONSOLE
   jmp unload_end
   
start_unload:
	CLI
    push DS
    mov AH, 35h
	mov AL, 1Ch
	int 21h

    mov SI, offset KEEP_IP
	sub SI, offset ROUT
	mov DX, ES:[BX+SI]
	mov AX, ES:[BX+SI+2]
    mov DS, AX
    mov AH, 25H
    mov AL, 1CH
    int 21H
    pop DS
   
    mov AX, ES:[BX+SI-2]
    mov ES, AX
    push ES
   
    mov AX, ES:[2Ch]
    mov ES, AX
    mov AH, 49h
    int 21h
   
    pop ES
    mov AH, 49h
    int 21h
    STI
   
    mov DX, offset WAS_INTERRUPT_FOR_UNLOADING
    call OUTPUTTING_STRING_TO_CONSOLE
    
unload_end:   
   pop SI
   pop AX
   ret
UNLOAD_INTERRUPT ENDP
;==============================================
Main PROC FAR
    push  DS       
    xor   AX,AX    
    push  AX       
    mov   AX,DATA             
    mov   DS,AX

    call LOAD_FLAG
    cmp flag, 1h
    je m_unload_interrupt
    jmp m_load_interrupt
   
m_unload_interrupt:
    call UNLOAD_INTERRUPT
    jmp real_end

m_load_interrupt:
    call LOAD_INTERRUPT
	jmp real_end

real_end:  
    mov AH, 4ch
    int 21h    
Main ENDP
CODE ENDS

ASTACK SEGMENT STACK
    dw 64 DUP(?)   
ASTACK ENDS

DATA SEGMENT
    flag db 0
	flag_load db 0

   	WAS_NO_INTERRUPT_FOR_UNLOADING db 'There was no interrupt to unload.', 0AH, 0DH,'$'
	WAS_INTERRUPT_FOR_UNLOADING db 'There was interrupt to unload. As a result, interrupt was unloaded.', 0AH, 0DH,'$'
	STRING_INTERRUPT_IS_ALREADY_LOADED db 'Interrupt is already loaded.', 0AH, 0DH,'$'
	STRING_LOADING_INTER db 'Interrupt was succesfully loaded.', 0AH, 0DH,'$'
DATA ENDS
    END Main
