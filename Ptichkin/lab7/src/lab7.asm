ASSUME CS:CODE, DS:DATA, SS:STACK

STACK SEGMENT STACK
	DW 128 DUP(?)
STACK ENDS

DATA SEGMENT
	EOF db 0dh, 0ah, '$'
	Error_file_message db 'Error! File not found!', 0dh, 0ah, '$' 
	Error_not_enough_mem_message db 'Eror! Not enough memory!', 0dh, 0ah, '$' 
	Error_route_message db 'Error! Route not found!', 0dh, 0ah, '$' 
	Error_mcb_crash_message db 'Error! MCB crashed!', 0dh, 0ah, '$' 
	Error_address_message db 'Error! Wrong memory address', 0dh, 0ah, '$'
	Error_load_func_message db 'Error! Wrong function!', 0dh, 0ah, '$' 
	Error_load_mem_message db 'Error! Wrong memory!', 0dh, 0ah, '$' 
	Error_load_files_message db 'Error! Too many files were opened!', 0dh, 0ah, '$'
	Error_load_env_message db 'Error! Wrong string of the enviroment ', 0dh, 0ah, '$'
	Error_load_access_message db 'Error! No access!', 0dh, 0ah, '$' 
    Free_mem_message db 'Memory was successfully freed' , 0dh, 0ah, '$'
	Success_load_message db  'Loaded successfully', 0dh, 0ah, '$'
	Success_mem_alloc_message db  'Memory was successfully allocated', 0dh, 0ah, '$'
	end_data db 0
	
	OVL_first db "ovl1.ovl", 0
	OVL_second db "ovl2.ovl", 0
	ovl_address dd 0	
	DTA_memory db 43 DUP(0)
	flag_memory db 0
	program DW 0
	CL_pos db 128 DUP(0)
	keep_psp DW 0
	
DATA ENDS

CODE SEGMENT

PRINT PROC
 	push ax
 	mov ah, 09h
 	int 21h
 	pop ax
 	ret
PRINT ENDP

ALLOCATE_MEM PROC
	push ax
	push bx
	push cx
	push dx

	push dx 
	mov dx, offset DTA_memory
	mov ah, 1ah
	int 21h
	
	pop dx 
	mov cx, 0
	mov ah, 4eh
	int 21h

	jnc Allocate_success

Allocate_file_error:
	cmp ax, 2
	je Allocate_route_error
	mov dx, offset Error_file_message
	call PRINT
	jmp Allocate_exit
	
Allocate_route_error:
	cmp ax, 3
	mov dx, offset Error_route_message
	call PRINT
	jmp Allocate_exit

Allocate_success:
	push di
	mov di, offset DTA_memory
	mov bx, [di+1ah] 
	mov ax, [di+1ch]
	pop di
	
	push cx
	mov cl, 4
	shr bx, cl
	mov cl, 12
	shl ax, cl
	pop cx
	add bx, ax
	add bx, 1
	mov ah, 48h
	int 21h
	
	mov word ptr ovl_address, ax
	mov dx, offset Success_mem_alloc_message
	call PRINT

Allocate_exit:
	pop dx
	pop cx
	pop bx
	pop ax
	ret
ALLOCATE_MEM ENDP

FREE_MEM PROC 
	push ax
	push bx
	push cx
	push dx
	
	mov ax, offset end_data
	mov bx, offset program_end
	
	add bx, ax
	mov cl, 4
	shr bx, cl
	add bx, 2bh
	mov ah, 4ah
	int 21h 

	jnc End_free_mem
	mov flag_memory, 1
	
	cmp ax, 7
	jne Error_memory
	mov dx, offset Error_mcb_crash_message
	call PRINT
	jmp Ret_mem_free	
Error_memory:
	cmp ax, 8
	jne Error_address
	mov dx, offset Error_not_enough_mem_message
	call PRINT
	jmp Ret_mem_free

	
Error_address:
	cmp ax, 9
	mov dx, offset Error_address_message
	call PRINT
	jmp Ret_mem_free
	
End_free_mem:
	mov flag_memory, 1
	mov dx, offset Free_mem_message
	call PRINT
	
Ret_mem_free:
	pop dx
	pop cx
	pop bx
	pop ax
	ret
FREE_MEM ENDP

LOAD_PROC PROC 
	push ax
	push bx
	push cx
	push dx
	push DS
	push es
	
	mov ax, DATA
	mov es, ax
	mov bx, offset ovl_address
	mov dx, offset CL_pos
	mov ax, 4b03h
	int 21h 
	
	jnc Load_success
	
	cmp ax, 1
	jne Load_error_file
	mov dx, offset EOF
	call PRINT
	
	mov dx, offset Error_load_func_message
	call PRINT
	jmp Load_error_exit
	
Load_error_file:
	cmp ax, 2
	jne Load_error_path
	mov dx, offset Error_file_message
	call PRINT
	jmp Load_error_exit
Load_error_path:
	cmp ax, 3
	jne Load_error_files
	mov dx, offset EOF
	call PRINT
	mov dx, offset Error_route_message
	call PRINT
	jmp Load_error_exit
Load_error_files:
	cmp ax, 4
	jne Load_error_access
	mov dx, offset Error_load_files_message
	call PRINT
	jmp Load_error_exit
Load_error_access:
	cmp ax, 5
	jne Load_error_mem
	mov dx, offset Error_load_access_message
	call PRINT
	jmp Load_error_exit
Load_error_mem:
	cmp ax, 8
	jne Load_error_enviroment
	mov dx, offset Error_load_mem_message
	call PRINT
	jmp Load_error_exit
Load_error_enviroment:
	cmp ax, 10
	mov dx, offset Error_load_env_message
	call PRINT
	jmp Load_error_exit

Load_success:
	mov dx, offset Success_load_message
	call PRINT
	
	mov ax, word ptr ovl_address
	mov es, ax
	mov word ptr ovl_address, 0
	mov word ptr ovl_address+2, ax

	call ovl_address
	mov es, ax
	mov ah, 49h
	int 21h

Load_error_exit:
	pop es
	pop DS
	pop dx
	pop cx
	pop bx
	pop ax
	ret
LOAD_PROC ENDP

PROC_ROUTE PROC 
	push ax
	push bx
	push cx 
	push dx
	push di
	push si
	push es
	
	mov program, dx

	mov ax, keep_psp
	mov es, ax
	mov es, es:[2ch]
	mov bx, 0
	
Find_:
	inc bx
	cmp byte ptr es:[bx-1], 0
	jne Find_

	cmp byte ptr es:[bx+1], 0 
	jne Find_
	
	add bx, 2
	mov di, 0
	
Route_loop:
	mov dl, es:[bx]
	mov byte ptr [CL_pos+di], dl
	inc di
	inc bx
	cmp dl, 0
	je Exit_main_route_loop
	cmp dl, '\'
	jne Route_loop
	mov cx, di
	jmp Route_loop
	
Exit_main_route_loop:
	mov di, cx
	mov si, program
	
Exit_fn:
	mov dl, byte ptr [si]
	mov byte ptr [CL_pos+di], dl
	inc di 
	inc si
	cmp dl, 0 
	jne Exit_fn

	pop es
	pop si
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	ret
PROC_ROUTE ENDP

LOAD_OVL PROC
	push dx
	call PROC_ROUTE
	mov dx, offset CL_pos
	call ALLOCATE_MEM
	call LOAD_PROC
	pop dx
	ret
LOAD_OVL ENDP

Main PROC FAR
	push DS
	xor ax, ax
	push ax
	
	mov ax, DATA
	mov DS, ax
	mov keep_psp, es
	
	call FREE_MEM 
	cmp flag_memory, 0
	je Exit_main

	mov dx, offset OVL_first
	call LOAD_OVL
	mov dx, offset EOF
	call PRINT
	
	mov dx, offset OVL_second
	call LOAD_OVL

Exit_main:
	xor al, al
	mov ah, 4ch
	int 21h
Main ENDP

program_end:
CODE ENDS
END Main