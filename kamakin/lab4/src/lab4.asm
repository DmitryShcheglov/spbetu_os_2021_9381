ETUSTACK SEGMENT STACK
    DW 64 DUP(?)   
ETUSTACK ENDS

CODE SEGMENT
   ASSUME CS:CODE, DS:DATA, SS:ETUSTACK

; Interruption for the task
INTERRUPTION_TASK PROC FAR
	jmp Proc_begin

	PSP_Z dw 0
	PSP_F dw 0
	CS_Keep dw 0
	IP_Keep dw 0
	INTERRUPTION_TASK_SET dw 0FEDCh
	StringCallCount db 'Interrupts call count: 0000  $'

Proc_begin:
	push   cx
	push   bx
	push   ax
	push   dx

    	call   SAVE_CURSOR
	push   dx
	
	mov    ah, 02h
	mov    bh, 00h
	mov    dx, 0220h
	int    10h 
	
	push   si
	push   cx
	push   ds
	mov    ax, SEG StringCallCount
	mov    ds, ax
	mov    si, offset StringCallCount
	add    si, 1Ah
	
	mov    ah, [si]
	inc    ah
	mov    [si], ah
	cmp    ah, 3Ah
	jne    Output_count
	mov    ah, 30h
	mov    [si], ah

	mov    bh, [si - 1]
	inc    bh
	mov    [si - 1], bh
	cmp    bh, 3Ah
	jne    Output_count
	mov    bh, 30h
	mov    [si - 1], bh

	mov    ch, [si - 2]
	inc    ch
	mov    [si - 2], ch
	cmp    ch, 3Ah
	jne    Output_count
	mov    ch, 30h
	mov    [si - 2], ch

	mov    dh, [si - 3]
	inc    dh
	mov    [si - 3], dh
	cmp    dh, 3Ah
	jne    Output_count
	mov    dh, 30h
	mov    [si - 3],dh

Output_count:
    	pop    ds
    	pop    cx
	pop    si

	push   es
	push   bp
	mov    ax, SEG StringCallCount
	mov    es, ax
	lea    ax, StringCallCount
	mov    bp, ax
	mov    ah, 13h
	mov    al, 00h
	mov    cx, 1Dh
	mov    bh, 0
	int    10h
	pop    bp
	pop    es

	pop    dx
	mov    ah, 02h
	mov    bh, 0h
	int    10h

	pop    bx
	pop    ax
	pop    dx
	pop    cx
	iret
INTERRUPTION_TASK ENDP

; Saves the cursor in BX
SAVE_CURSOR PROC NEAR
    	push   ax
    	push   bx
    
	mov    ah, 03h
	mov    bh, 00h
	int    10h
	
	pop    bx
	pop    ax
	ret
SAVE_CURSOR ENDP

MEMORY_PROC PROC
MEMORY_PROC ENDP

CHECK_INTERRUPTION PROC NEAR
	push   bx
	push   dx
	push   es

	mov    ah, 35h
	mov    al, 1Ch
	int    21h

	mov    dx, es:[bx + 11]
	cmp    dx, 0FEDCh
	je     Interruption_set
	mov    al, 00h
	jmp    Exit_proc

Interruption_set:
	mov    al, 01h

Exit_proc:
	pop    es
	pop    dx
	pop    bx
	ret
CHECK_INTERRUPTION ENDP

; Check if the program was launched with '/un' argument
CHECK_ARGUMENT PROC NEAR
	push   es

	mov    ax, PSP_Z
	mov    es, ax
	mov    bx, 0082h

	mov    al, es:[bx]
	inc    bx
	cmp    al, '/'
	jne    Null
	
	mov    al, es:[bx]
	inc    bx
	cmp    al, 'u'
	jne    Null
	
	mov    al, es:[bx]
	inc    bx
	cmp    al, 'n'
	jne    Null

	mov    al, 0001h
Null:
	pop    es
	ret
CHECK_ARGUMENT ENDP

INTERRUPTION_UNLOAD PROC NEAR
	push   ax
	push   bx
	push   dx
	push   es

	mov    ah, 35h
	mov    al, 1Ch
	int    21h
	cli
	push   ds
	mov    dx, es:[bx + 9]
	mov    ax, es:[bx + 7]
	mov    ds, ax
	mov    ah, 25h
	mov    al, 1Ch
	int    21h
	pop    ds
	sti

	lea    dx, StringInterruptionRestored
	call   OUTPUT

	push   es
	mov    cx, es:[bx + 3]
	mov    es, cx
	mov    ah, 49h
	int    21h
	pop    es

	mov    cx, es:[bx + 5]
	mov    es, cx
	int    21h
	pop    es
	pop    dx
	pop    bx
	pop    ax
	ret
INTERRUPTION_UNLOAD ENDP

INTERRUPTION_LOAD PROC NEAR
	push   ax
	push   bx
	push   dx
	push   es

	mov    ah, 35h
	mov    al, 1Ch
	int    21h

	mov    IP_Keep, bx
	mov    CS_Keep, es

	push   ds
	lea    dx, INTERRUPTION_TASK
	mov    ax, seg INTERRUPTION_TASK
	mov    ds, ax
	mov    ah, 25h
	mov    al, 1Ch
	int    21h
	pop    ds

	lea    dx, StringInterruptionLoading
	call   OUTPUT
	pop    es
	pop    dx
	pop    bx
	pop    ax
	ret
INTERRUPTION_LOAD ENDP

OUTPUT PROC NEAR
	push   ax
	mov    ah, 09h
	int    21h
	pop    ax
	ret
OUTPUT ENDP

MAIN PROC FAR
	mov    bx, 02Ch
	mov    ax, [bx]
	mov    PSP_F, ax
	mov    PSP_Z, ds
	sub    ax, ax
	sub    bx, bx

	mov    ax, DATA
	mov    ds, ax

	call   CHECK_ARGUMENT
	cmp    al, 01h
	je     Interruption_unload_begin

	call   CHECK_INTERRUPTION
	cmp    al, 01h
	jne    Interruption_not_loaded

	lea    dx, StringInterruptionLoaded
	call   OUTPUT
	
	jmp    End_main
	mov    ah, 4Ch
	int    21h

Interruption_not_loaded:
	call   INTERRUPTION_LOAD

	mov    dx, offset MEMORY_PROC
	mov    cl, 04h
	shr    dx, cl
	add    dx, 1Bh
	mov    ax, 3100h
	int    21h

Interruption_unload_begin:
	call   CHECK_INTERRUPTION
	call   INTERRUPTION_UNLOAD

End_main:
    	xor    al, al
	mov    ah, 4Ch
	int    21h
MAIN ENDP

CODE ENDS

DATA  SEGMENT
	StringInterruptionLoaded db "The interruption handler is already loaded", 0DH, 0AH, '$'
	StringInterruptionLoading db "The interruption handler is loading", 0DH, 0AH, '$'
	StringInterruptionRestored db "The interruption handler is restored", 0DH, 0AH, '$'
DATA ENDS

END MAIN
