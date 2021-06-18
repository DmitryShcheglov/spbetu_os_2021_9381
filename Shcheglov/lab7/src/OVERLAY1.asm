CODE SEGMENT
    ASSUME CS:CODE, DS:NOTHING, SS:NOTHING, ES:NOTHING
;==============================================
Main PROC FAR
    push 	DS
	push 	DI
	push 	AX
	push 	DX
    mov AX, CS
	mov DS, AX
    mov DI, offset ADDRESS_OF_THE_OVERLAY
    add DI, 40
    call WRD_TO_HEX
    mov DX, offset ADDRESS_OF_THE_OVERLAY
    call OUTPUTTING_STRING_TO_CONSOLE
    pop 	DX
	pop 	AX
	pop 	DI
	pop 	DS
    retf
Main ENDP
;==============================================
ADDRESS_OF_THE_OVERLAY db 'Address of the first overlay is             ', 0DH, 0AH, '$'
;==============================================
OUTPUTTING_STRING_TO_CONSOLE PROC near
	push AX
	mov AH, 09h
	int 21h
	pop AX
	ret
OUTPUTTING_STRING_TO_CONSOLE ENDP
;==============================================
TETR_TO_HEX PROC near
    and AL, 0Fh
    cmp AL, 09
    jbe NEXT
    add AL, 07
NEXT:
    add AL, 30h
    ret
TETR_TO_HEX ENDP
;==============================================
BYTE_TO_HEX PROC near
    push CX
    mov AH, AL
    call TETR_TO_HEX
    xchg AL, AH
    mov CL, 4
    shr AL, CL
    call TETR_TO_HEX
    pop CX
    ret
BYTE_TO_HEX ENDP
;==============================================
WRD_TO_HEX PROC near
    push BX
    mov BH, AH
    call BYTE_TO_HEX
    mov [DI], AH
    dec DI
    mov [DI], AL
    dec DI
    mov AL, BH
    call BYTE_TO_HEX
    mov [DI], AH
    dec DI
    mov [DI], AL
    pop BX
    ret
WRD_TO_HEX ENDP
;==============================================
CODE ENDS
END