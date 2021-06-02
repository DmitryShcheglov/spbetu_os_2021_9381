ASSUME CS:CODE, DS:DATA, SS:LAB_STACK

LAB_STACK SEGMENT STACK
	DW 128 DUP(?)
LAB_STACK ENDS

DATA  SEGMENT
	paramsBlock    dw 0 
					dd 0 
					dd 0 
					dd 0  
	programName db 'LR2.COM', 0 
   
	cmd db 1h, 0dh
	pos db 128 dup(0)              
	ssKeep dw 0
	spKeep dw 0
	pspKeep dw 0
   
	memoryDestroyed db 'Destroyed memory block',13,10,'$'
	memoryLowMemFunc db 'Not enough memory for running function',13,10,'$'
	memoryWrongMemAdr db 'Incorrect memory address',13,10,'$'
	
	errorWrongFuncNum  db 'Wrong function number',13,10,'$' 				
	errorMissFile  db 'File was not found',13,10,'$'
	errorDisk  db 'Disk error',13,10,'$'
	errorNotEnoughMem  db 'Not enough free disk memory space',13,10,'$'
	errorWrongStrFormat db 'Wrong string enviroment',13,10,'$'
	errorWrongFormat db 'Wrong format',13,10,'$'
	
	endSuccess db 'Normal ending with code     ',13,10,'$'
	endCtrlBreak db 'Program was interrupted by ctrl-break',13,10,'$'
	endDeviceError db 'Program was ended with device error',13,10,'$'
	endInterruption db 'Program was ended by int 31h interruption',13,10,'$'
	
	end_data db 0
	DATA ENDS

	CODE SEGMENT

	PRINT PROC
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
	PRINT ENDP

	FREE_MEMORY PROC
	push ax
	push bx
	push cx
	push dx
	
	mov ax, offset end_data
	mov bx, offset END_APP
	add bx, ax
	shr bx, 1
	shr bx, 1
	shr bx, 1
	shr bx, 1
	add bx, 2bh
	mov ah, 4ah
	int 21h

	jnc END_FREE_MEMORY
	
	lea dx, memoryDestroyed
	cmp ax, 7
	je WRITE_MEMORY_COMMENT
	lea dx, memoryLowMemFunc
	cmp ax, 8	
	je WRITE_MEMORY_COMMENT
	lea dx, memoryWrongMemAdr	
	cmp ax, 9
	je WRITE_MEMORY_COMMENT	
	jmp END_FREE_MEMORY
   
WRITE_MEMORY_COMMENT:
	mov ah, 09h
	int 21h
   
END_FREE_MEMORY: 
	pop dx
	pop cx  
	pop bx	
	pop ax
	ret
FREE_MEMORY ENDP

SET_FULL_PROG_NAME PROC NEAR
	push ax
	push bx
	push cx	
	push dx
	push di	
	push si
	push es
   
	mov ax, pspKeep
	mov es, ax	
	mov es, es:[2ch]
	mov bx, 0
	
FIND_SMTH:
	inc bx
	cmp byte ptr es:[bx-1], 0
	jne FIND_SMTH
	cmp byte ptr es:[bx+1], 0
	jne FIND_SMTH
	
	add bx, 2
	mov di, 0
	
FIND_LOOP:
	mov dl, es:[bx]
	mov byte ptr [pos + di], dl
	inc di
	inc bx
	cmp dl, 0
	je END_LOOP
	cmp dl, '\'
	jne FIND_LOOP
	mov cx, di
	jmp FIND_LOOP
END_LOOP:
	mov di, cx
	mov si, 0
	
LOOP_2:
	mov dl, byte ptr[programName + si]
	mov byte ptr [pos + di], dl
	inc di
	inc si
	cmp dl, 0
	jne LOOP_2
	
	pop es
	pop si
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	ret
SET_FULL_PROG_NAME ENDP

DEPLOY_ANOTHER_PROGRAM PROC NEAR
	push ax
	push bx
	push cx
	push dx
	push ds
	push es
	mov spKeep, sp
	mov ssKeep, ss
	mov ax, DATA
	mov es, ax
	mov dx, offset cmd
	mov bx, offset paramsBlock
	mov [bx+2], dx
	mov [bx+4], ds
	mov dx, offset pos
	
	mov ax, 4B00h
	int 21h
	
	mov ss, ssKeep
	mov sp, spKeep
	
	pop es
	pop ds  
	
	jnc END_SUCCESS
		
ERROR_1:
	cmp ax, 1
	jne ERROR_2
	mov dx, offset errorWrongFuncNum
	call PRINT
	jmp DEPLOY_END
	
ERROR_2:
	cmp ax, 2
	jne ERROR_3
	mov dx, offset errorMissFile
	call PRINT
	jmp DEPLOY_END
	
ERROR_3: ;5
	cmp ax, 5
	jne ERROR_4
	mov dx, offset errorDisk
	call PRINT
	jmp DEPLOY_END

ERROR_4: ;8
	cmp ax, 8
	jne ERROR_5
	mov dx, offset errorNotEnoughMem
	call PRINT
	jmp DEPLOY_END

ERROR_5: ;10
	cmp ax, 10
	jne ERROR_6
	mov dx, offset errorWrongStrFormat
	call PRINT
	jmp DEPLOY_END
	
ERROR_6: ;11
	cmp ax, 11
	mov dx, offset errorWrongFormat
	call PRINT
	jmp DEPLOY_END
	
END_SUCCESS:
	mov ax, 4D00h
	int 21h
	
	cmp ah, 0
	jne END_1
	push di
	mov di, offset endSuccess
	mov [di+26], al
	pop si
	mov dx, offset endSuccess
	call PRINT
	jmp DEPLOY_END

END_1:
	cmp ah, 1
	jne END_2
	mov dx, offset endCtrlBreak
	call PRINT
	jmp DEPLOY_END
	
END_2:
	cmp ah, 2
	jne END_3
	mov dx, offset endDeviceError
	call PRINT
	jmp DEPLOY_END
	
END_3:
	cmp ah, 3
	mov dx, offset endInterruption
	call PRINT
	
DEPLOY_END:
	pop dx
	pop cx
	pop bx
	pop ax
	ret
DEPLOY_ANOTHER_PROGRAM ENDP

MAIN PROC FAR
	push ds
	xor   ax, ax
	push  ax
	mov   ax, DATA
	mov   ds, ax
	mov pspKeep, es
	call FREE_MEMORY
	call SET_FULL_PROG_NAME
	call DEPLOY_ANOTHER_PROGRAM
   
VERY_END:
	xor al,al
	mov ah,4ch
	int 21h
	MAIN ENDP
	
END_APP:

CODE ENDS
	END MAIN