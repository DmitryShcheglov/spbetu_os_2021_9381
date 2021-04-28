ETUSTACK SEGMENT STACK 
	DW 64 DUP(?)
ETUSTACK ENDS

CODE SEGMENT
    	ASSUME CS:CODE, DS:DATA, SS:ETUSTACK


INTERRUPTION_TASK PROC FAR
	jmp Proc_begin
	
	CS_Keep dw 0                               
	IP_Keep dw 0                           
	curr_psp dw 0      							                   
	mem_addr_psp dw 0	                          	
	INTERRUPTION_TASK_SET dw 0fedch           
	SS_keep dw 0						
	SP_keep dw 0						
	AX_keep dw 0						
	StringCallCount db 'Count of interruptions: 0000  $' 
	stack_new dw 64 DUP(?)
	
Proc_begin:
	mov    SP_keep, sp 
    	mov    AX_keep, ax
   	mov    SS_keep, SS
    	mov    sp, offset Proc_begin
    	mov    ax, seg stack_new
    	mov    SS, ax
    
   	push   ax      
	push   bx
	push   cx
	push   dx
	
	mov    ah, 03h 
	mov    bh, 0h 
	int    10h

	push   dx 
	
	mov    ah, 02h 
	mov    bh, 0h
	mov    bl, 02h
	mov    dx, 0h
	int    10h

	push   si
	push   cx
	push   DS

	mov    ax, seg StringCallCount
	mov    DS, ax
	mov    si, offset StringCallCount
	add    si, 27
	mov    cx, 4

interr_loop:
	mov    ah, [si]
	inc    ah
	mov    [si], ah
	cmp    ah, 3ah
	jne    Output_count
	mov    ah, 30h
	mov    [si], ah	
	dec    si
	loop   interr_loop
	
Output_count:
    	pop    ds
    	pop    cx
	pop    si
	
	push   es
	push   bp
	mov    ax, seg StringCallCount
	mov    es, ax
	mov    ax, offset StringCallCount
	mov    bp, ax
	mov    ah, 13h
	mov    al, 00h
	mov    cx, 28
	mov    bh, 0
	int    10h
	pop    bp
	pop    es

	pop    dx
	mov    ah, 02h
	mov    bh, 0h
	int    10h

	pop    dx
	pop    cx
	pop    bx
	pop    ax  
		
    	mov    ss, SS_keep
    	mov    ax, AX_keep
	mov    sp, SP_keep
	iret
INTERRUPTION_TASK ENDP

CHECK_INTERRUPTION PROC NEAR
	push   bx
	push   dx
	push   es

	mov    ah, 35h
	mov    al, 1ch
	int    21h

	mov    dx, es:[bx + 11]
	cmp    dx, 0FEDCh
	je     Interruption_set
	mov    al, 00h
	jmp    Exit_proc

Interruption_set:
	mov al, 01h

Exit_proc:
	pop es
	pop dx
	pop bx
	ret
CHECK_INTERRUPTION ENDP

MEMORY_PROC:

CHECK_ARGUMENT PROC NEAR
	push   es
	
	mov    ax, curr_psp
	mov    es, ax
	
	mov    al, es:[81h+1]
	cmp    al, '/'
	jne    Null

	mov    al, es:[81h+2]
	cmp    al, 'u'
	jne    Null

	mov    al, es:[81h+3]
	cmp    al, 'n'
	jne    Null
	
	mov    al, 0001h
Null:
	pop es
	ret
CHECK_ARGUMENT ENDP

INTERRUPTION_UNLOAD PROC NEAR
	push   ax
	push   bx
	push   dx
	push   es

	mov    ah, 35h
	mov    al, 1ch
	int    21h

	push   ds   

	mov    dx, es:[bx + 5]  
	mov    ax, es:[bx + 3]
	mov    ds, ax
	mov    ah, 25h
	mov    al, 1ch
	int    21h 
	pop    ds
	sti
	
	mov    dx, offset StringInterruptionUnload
	call   OUTPUT

	push   es	
	mov    cx, es:[bx + 7]
	mov    es, cx
	mov    ah, 49h
	int    21h

	pop    es
	mov    cx, es:[bx + 9] 
	mov    es, cx
	int    21h
	pop es
	
	pop dx
	pop bx
	pop ax
	ret
INTERRUPTION_UNLOAD ENDP

INTERRUPTION_LOAD PROC NEAR
	push   ax
	push   bx
	push   dx
	push   es

	mov    ah, 35h 
	mov    al, 1ch
	int    21h
	
	mov    IP_Keep, bx
	mov    CS_Keep, es

	push   ds
	mov    dx, offset INTERRUPTION_TASK
	mov    ax, seg INTERRUPTION_TASK
	mov    ds, ax
	mov    ah, 25h 
	mov    al, 1ch 
	int    21h 
	pop    ds

	mov    dx, offset StringInterruptionWasLoaded
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
	int	   21h
	pop    ax
	ret
OUTPUT ENDP

MAIN PROC FAR
	mov    bx, 02ch
	mov    ax, [bx]
	mov    mem_addr_psp, ax
	mov    curr_psp, DS  
	xor    ax, ax    
	xor    bx, bx

	mov    ax, DATA  
	mov    DS, ax    

	call   CHECK_ARGUMENT  
	cmp    al, 01h
	je     Interruption_unload_begin

	call   CHECK_INTERRUPTION  
	cmp    al, 01h
	jne    Interruption_not_loaded
	
	mov    dx, offset StringInterruptionLoaded	
	call   OUTPUT
	jmp    End_main
       
	mov    ah,4ch
	int    21h

Interruption_not_loaded:
	call   INTERRUPTION_LOAD
	
	mov    dx, offset MEMORY_PROC
	mov    cl, 04h
	shr    dx, cl
	add    dx, 1bh
	mov    ax, 3100h
	int    21h
         
Interruption_unload_begin:
	call   CHECK_INTERRUPTION
	cmp    al, 00h
	je     Interruption_not_set
	call   INTERRUPTION_UNLOAD
	jmp    End_main

Interruption_not_set:
	mov    dx, offset StringInterruptionNotLoaded
	call   OUTPUT
	
End_main:
	mov    ah, 4ch
	int    21h
MAIN ENDP

CODE ENDS

DATA SEGMENT
	StringInterruptionNotLoaded db "interrupt not loaded", 0DH, 0AH, '$'
	StringInterruptionUnload db "interrupt unloaded", 0DH, 0AH, '$'
	StringInterruptionLoaded db "interrupt is already load", 0DH, 0AH, '$'
	StringInterruptionWasLoaded db "interrupt was loaded", 0DH, 0AH, '$'
DATA ENDS

END MAIN
