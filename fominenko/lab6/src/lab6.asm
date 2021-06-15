STACK SEGMENT STACK
	DW 128 DUP(?)
STACK ENDS

DATA SEGMENT
	program db 'lab2.com', 0	
	flag db 0
	cmd db 1h, 0dh
	pos db 128 DUP(0)
	keep_ss DW 0
	keep_sp DW 0
	keep_psp DW 0
	Block_param DW 0
               dd 0
               dd 0
               dd 0

	Memory_free_message db 'Memory has been freed' , 0dh, 0ah, '$'
    Error_crash_message db 'Error! MCB crashed!', 0dh, 0ah, '$' 
	Error_no_memory_message db 'Error! Not enough memory!', 0dh, 0ah, '$' 
	Error_address_message db 'Error! Invalid memory address!', 0dh, 0ah, '$'
	Error_fun_num_message db 'Error! Invalid function number!', 0dh, 0ah, '$' 
	Error_no_file_message db 'Error! File not found!', 0dh, 0ah, '$' 
	Error_disk_message db 'Error with disk!', 0dh, 0ah, '$' 
	Error_memory_message db 'Error! Insufficient memory!', 0dh, 0ah, '$' 
	Error_enviroment_message db 'Error! Wrong string of environment!', 0dh, 0ah, '$' 
	Error_format_message db 'Error! Wrong format!', 0dh, 0ah, '$' 
	Error_Device_message db 0dh, 0ah, 'Error! Device error!' , 0dh, 0ah, '$'
	End_code_message db 0dh, 0ah, 'The program successfully ended with code:    ' , 0dh, 0ah, '$'
	End_ctrl_message db 0dh, 0ah, 'The program was interrupted by ctrl-break' , 0dh, 0ah, '$'
	End_int_message db 0dh, 0ah, 'The program was ended by interruption int 31h' , 0dh, 0ah, '$'

	End_data db 0
DATA ENDS

CODE SEGMENT

assume cs:CODE, ds:DATA, ss:STACK

PRINT PROC 
 	push ax
 	mov ah, 09h
 	int 21h 
 	pop ax
 	ret
PRINT ENDP 

FREE_MEM PROC 
	push ax
	push bx
	push cx
	push dx
	
	mov ax, offset End_data
	mov bx, offset end_program
	add bx, ax
	
	mov cl, 4
	shr bx, cl
	add bx, 2bh
	mov ah, 4ah
	int 21h 

	jnc End_mem_free
	mov flag, 1
	
Crash_mcb:
	cmp ax, 7
	jne No_mem
	mov dx, offset Error_crash_message
	call PRINT
	jmp Ret_func	
No_mem:
	cmp ax, 8
	jne Error_address
	mov dx, offset Error_no_memory_message
	call PRINT
	jmp Ret_func	
Error_address:
	cmp ax, 9
	mov dx, offset Error_address_message
	call PRINT
	jmp Ret_func
End_mem_free:
	mov flag, 1
	mov dx, offset Memory_free_message
	call PRINT
	
Ret_func:
	pop dx
	pop cx
	pop bx
	pop ax
	ret
FREE_MEM ENDP

LOAD PROC 
	push ax
	push bx
	push cx
	push dx
	push ds
	push es
	
	mov keep_sp, sp
	mov keep_ss, ss
	
	mov ax, DATA
	mov es, ax
	mov bx, offset Block_param
	mov dx, offset cmd
	mov [bx + 2], dx
	mov [bx + 4], ds 
	mov dx, offset pos
	
	mov ax, 4b00h 
	int 21h 
	
	mov ss, keep_ss
	mov sp, keep_sp
	pop es
	pop ds
	
	jnc Loads
	
	cmp ax, 1
	jne Error_file
	mov dx, offset Error_fun_num_message
	call PRINT
	jmp Load_exit
Error_file:
	cmp ax, 2
	jne Error_Disk
	mov dx, offset Error_no_file_message
	call PRINT
	jmp Load_exit
Error_Disk:
	cmp ax, 5
	jne Error_mem
	mov dx, offset Error_disk_message
	call PRINT
	jmp Load_exit
Error_mem:
	cmp ax, 8
	jne Error_enviroment
	mov dx, offset Error_memory_message
	call PRINT
	jmp Load_exit
Error_enviroment:
	cmp ax, 10
	jne Error_format
	mov dx, offset Error_enviroment_message
	call PRINT
	jmp Load_exit
Error_format:
	cmp ax, 11
	mov dx, offset Error_format_message
	call PRINT
	jmp Load_exit

Loads:
	mov ah, 4dh
	mov al, 00h
	int 21h 
	
	cmp ah, 0
	jne Jump_ctrl
	push di 
	mov di, offset End_code_message
	mov [di + 44], al 
	pop si
	mov dx, offset End_code_message
	call PRINT 
	jmp Load_exit
Jump_ctrl:
	cmp ah, 1
	jne Device
	mov dx, offset End_ctrl_message 
	call PRINT 
	jmp Load_exit
Device:
	cmp ah, 2 
	jne Interrup_jump
	mov dx, offset Error_Device_message
	call PRINT 
	jmp Load_exit
Interrup_jump:
	cmp ah, 3
	mov dx, offset End_int_message
	call PRINT 

Load_exit:
	pop dx
	pop cx
	pop bx
	pop ax
	ret
LOAD ENDP

PATH PROC 
	push ax
	push bx
	push cx 
	push dx
	push di
	push si
	push es
	
	mov ax, keep_psp
	mov es, ax
	mov es, es:[2ch]
	mov bx, 0
	
Find_path:
	inc bx
	cmp byte ptr es:[bx - 1], 0
	jne Find_path

	cmp byte ptr es:[bx + 1], 0 
	jne Find_path
	
	add bx, 2
	mov di, 0
	
Find_loop:
	mov dl, es:[bx]
	mov byte ptr [pos + di], dl
	inc di
	inc bx
	cmp dl, 0
	je Exit_find_loop
	cmp dl, '\'
	jne Find_loop
	mov cx, di
	jmp Find_loop
Exit_find_loop:
	mov di, cx
	mov si, 0
	
End_fn:
	mov dl, byte ptr [program + si]
	mov byte ptr [pos + di], dl
	inc di 
	inc si
	cmp dl, 0 
	jne End_fn
		
	pop es
	pop si
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	ret
PATH ENDP

MAIN PROC far
	push ds
	xor ax, ax
	push ax
	mov ax, DATA
	mov ds, ax
	mov keep_psp, es
	call FREE_MEM 
	cmp flag, 0
	je exit
	call PATH
	call LOAD
exit:
	xor al, al
	mov ah, 4ch
	int 21h
MAIN ENDP

end_program:
CODE ENDS
END MAIN
