MYSTACK SEGMENT STACK 
	DW 64 DUP(?)
MYSTACK ENDS

CODE SEGMENT
    	ASSUME CS:CODE, DS:DATA, SS:MYSTACK


MY_INTERRUPTION PROC FAR
	jmp begin_inter
	
	keep_cs dw 0                               
	keep_ip dw 0                           
	psp_state dw 0      							                   
	psp_adress dw 0	                          	
	interruotion_set dw 0fedch           
	keep_ss dw 0						
	keep_sp dw 0						
	keep_ax dw 0						
	inter_amount_mes db 'Count of interruptions: 0000  $' 
	new_stack dw 64 DUP(?)
	
begin_inter:
	mov    keep_sp, sp 
    mov    keep_ax, ax
   	mov    keep_ss, SS
    mov    sp, offset begin_inter
    mov    ax, seg new_stack
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

	mov    ax, seg inter_amount_mes
	mov    DS, ax
	mov    si, offset inter_amount_mes
	add    si, 27
	mov    cx, 4

make_inter:
	mov    ah, [si]
	inc    ah
	mov    [si], ah
	cmp    ah, 3ah
	jne    get_amount
	mov    ah, 30h
	mov    [si], ah	
	dec    si
	loop   make_inter
	
get_amount:
    	pop    ds
    	pop    cx
	pop    si
	
	push   es
	push   bp
	mov    ax, seg inter_amount_mes
	mov    es, ax
	mov    ax, offset inter_amount_mes
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
		
    	mov    ss, keep_ss
    	mov    ax, keep_ax
	mov    sp, keep_sp
	iret
MY_INTERRUPTION ENDP

IS_INTER_WORKING PROC NEAR
	push   bx
	push   dx
	push   es

	mov    ah, 35h
	mov    al, 1ch
	int    21h

	mov    dx, es:[bx + 11]
	cmp    dx, 0FEDCh
	je     is_working
	mov    al, 00h
	jmp    end_check

is_working:
	mov al, 01h

end_check:
	pop es
	pop dx
	pop bx
	ret
IS_INTER_WORKING ENDP

MEMORY_PROC:

IS_END_CMD PROC NEAR
	push   es
	
	mov    ax, psp_state
	mov    es, ax
	
	mov    al, es:[81h+1]
	cmp    al, '/'
	jne    wrong_cmd

	mov    al, es:[81h+2]
	cmp    al, 'u'
	jne    wrong_cmd

	mov    al, es:[81h+3]
	cmp    al, 'n'
	jne    wrong_cmd
	
	mov    al, 0001h
wrong_cmd:
	pop es
	ret
IS_END_CMD ENDP

UNLOAD_INTER PROC NEAR
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
	
	mov    dx, offset unload_mes
	call   PRINT_MES

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
UNLOAD_INTER ENDP

LOAD_INTER PROC NEAR
	push   ax
	push   bx
	push   dx
	push   es

	mov    ah, 35h 
	mov    al, 1ch
	int    21h
	
	mov    keep_ip, bx
	mov    keep_cs, es

	push   ds
	mov    dx, offset MY_INTERRUPTION
	mov    ax, seg MY_INTERRUPTION
	mov    ds, ax
	mov    ah, 25h 
	mov    al, 1ch 
	int    21h 
	pop    ds

	mov    dx, offset load_mes
	call   PRINT_MES

	pop    es
	pop    dx
	pop    bx
	pop    ax
	ret
LOAD_INTER ENDP

PRINT_MES PROC NEAR
	push   ax
	mov    ah, 09h
	int	   21h
	pop    ax
	ret
PRINT_MES ENDP

MAIN PROC FAR
	mov    bx, 02ch
	mov    ax, [bx]
	mov    psp_adress, ax
	mov    psp_state, DS  
	xor    ax, ax    
	xor    bx, bx

	mov    ax, DATA  
	mov    DS, ax    

	call   IS_END_CMD  
	cmp    al, 01h
	je     unload_start

	call   IS_INTER_WORKING  
	cmp    al, 01h
	jne    no_inter
	
	mov    dx, offset already_load_mes	
	call   PRINT_MES
	jmp    main_end
       
	mov    ah,4ch
	int    21h

no_inter:
	call   LOAD_INTER
	
	mov    dx, offset MEMORY_PROC
	mov    cl, 04h
	shr    dx, cl
	add    dx, 1bh
	mov    ax, 3100h
	int    21h
         
unload_start:
	call   IS_INTER_WORKING
	cmp    al, 00h
	je     no_set_inter
	call   UNLOAD_INTER
	jmp    main_end

no_set_inter:
	mov    dx, offset no_inter_loaded_mes
	call   PRINT_MES
	
main_end:
	mov    ah, 4ch
	int    21h
MAIN ENDP

CODE ENDS

DATA SEGMENT
	no_inter_loaded_mes db "Interruption is not loaded!", 0DH, 0AH, '$'
	unload_mes db "Interruption has been unloaded!", 0DH, 0AH, '$'
	already_load_mes db "Interruption has been already loaded!", 0DH, 0AH, '$'
	load_mes db "Interruption is loaded!", 0DH, 0AH, '$'
DATA ENDS

END MAIN
