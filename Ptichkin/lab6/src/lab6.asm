STACK SEGMENT STACK
	DW 128 DUP(?)
STACK ENDS

DATA SEGMENT
	program db 'lab2.com', 0	
	flag db 0
	cmd db 1h, 0dh
	pos db 128 DUP(0)
	ssKeep DW 0
	spKeep DW 0
	pspKeep DW 0
	blockParam DW 0
               dd 0
               dd 0
               dd 0

	StringMemoryFree db 'Memory was freed' , 0dh, 0ah, '$'
    StringErrorCrash db 'Error! MCB crashed!', 0dh, 0ah, '$' 
	StringErrorNoMemory db 'Error! Not enough memory!', 0dh, 0ah, '$' 
	StringErrorAddress db 'Error! Invalid memory addressess!', 0dh, 0ah, '$'
	StringErrorFunNumber db 'Error! Invalid function number!', 0dh, 0ah, '$' 
	StringErrorNoFile db 'Error! File not found!', 0dh, 0ah, '$' 
	StringErrorDisk db 'Error with disk!', 0dh, 0ah, '$' 
	StringErrorMemory db 'Error! Insufficient memory!', 0dh, 0ah, '$' 
	StringErrorEnviroment db 'Error! Wrong string of environment!', 0dh, 0ah, '$' 
	StringErrorFormat db 'Error! Wrong format!', 0dh, 0ah, '$' 
	StringErrorDevice db 0dh, 0ah, 'Error! Device error!' , 0dh, 0ah, '$'
	StringEndCode db 0dh, 0ah, 'The program successfully ended with code:    ' , 0dh, 0ah, '$'
	StringEndCtrl db 0dh, 0ah, 'The program was interrupted by ctrl-break' , 0dh, 0ah, '$'
	StringEndInt db 0dh, 0ah, 'The program was ended by interruption int 31h' , 0dh, 0ah, '$'

	dataEnd db 0
DATA ENDS

CODE SEGMENT

assume cs:CODE, ds:DATA, ss:STACK

output PROC 
 	push ax
 	mov ah, 09h
 	int 21h 
 	pop ax
 	ret
output ENDP 

memoryFree PROC 
	push ax
	push bx
	push cx
	push dx
	
	mov ax, offset dataEnd
	mov bx, offset ENDProgram
	add bx, ax
	
	mov cl, 4
	shr bx, cl
	add bx, 2bh
	mov ah, 4ah
	int 21h 

	jnc endMemoryFree
	mov flag, 1
	
crashMCB:
	cmp ax, 7
	jne noMemory
	mov dx, offset StringErrorCrash
	call output
	jmp retFunction	
noMemory:
	cmp ax, 8
	jne errorAddress
	mov dx, offset StringErrorNoMemory
	call output
	jmp retFunction	
errorAddress:
	cmp ax, 9
	mov dx, offset StringErrorAddress
	call output
	jmp retFunction
endMemoryFree:
	mov flag, 1
	mov dx, offset StringMemoryFree
	call output
	
retFunction:
	pop dx
	pop cx
	pop bx
	pop ax
	ret
memoryFree ENDP

load PROC 
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
	mov bx, offset blockParam
	mov dx, offset cmd
	mov [bx + 2], dx
	mov [bx + 4], ds 
	mov dx, offset pos
	
	mov ax, 4b00h 
	int 21h 
	
	mov ss, ssKeep
	mov sp, spKeep
	pop es
	pop ds
	
	jnc loads
	
	cmp ax, 1
	jne errorFile
	mov dx, offset StringErrorFunNumber
	call output
	jmp loadExit
errorFile:
	cmp ax, 2
	jne errorDisk
	mov dx, offset StringErrorNoFile
	call output
	jmp loadExit
errorDisk:
	cmp ax, 5
	jne errorMemory
	mov dx, offset StringErrorDisk
	call output
	jmp loadExit
errorMemory:
	cmp ax, 8
	jne errorEnviroment
	mov dx, offset StringErrorMemory
	call output
	jmp loadExit
errorEnviroment:
	cmp ax, 10
	jne errorFormat
	mov dx, offset StringErrorEnviroment
	call output
	jmp loadExit
errorFormat:
	cmp ax, 11
	mov dx, offset StringErrorFormat
	call output
	jmp loadExit

loads:
	mov ah, 4dh
	mov al, 00h
	int 21h 
	
	cmp ah, 0
	jne jumpCtrl
	push di 
	mov di, offset StringEndCode
	mov [di + 44], al 
	pop si
	mov dx, offset StringEndCode
	call output 
	jmp loadExit
jumpCtrl:
	cmp ah, 1
	jne device
	mov dx, offset StringEndCtrl 
	call output 
	jmp loadExit
device:
	cmp ah, 2 
	jne interruptionJump
	mov dx, offset StringErrorDevice
	call output 
	jmp loadExit
interruptionJump:
	cmp ah, 3
	mov dx, offset StringEndInt
	call output 

loadExit:
	pop dx
	pop cx
	pop bx
	pop ax
	ret
load ENDP

path PROC 
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
	
findPath:
	inc bx
	cmp byte ptr es:[bx - 1], 0
	jne findPath

	cmp byte ptr es:[bx + 1], 0 
	jne findPath
	
	add bx, 2
	mov di, 0
	
findLoop:
	mov dl, es:[bx]
	mov byte ptr [pos + di], dl
	inc di
	inc bx
	cmp dl, 0
	je exitfindLoop
	cmp dl, '\'
	jne findLoop
	mov cx, di
	jmp findLoop
exitfindLoop:
	mov di, cx
	mov si, 0
	
endFn:
	mov dl, byte ptr [program + si]
	mov byte ptr [pos + di], dl
	inc di 
	inc si
	cmp dl, 0 
	jne endFn
		
	pop es
	pop si
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	ret
path ENDP

begin PROC far
	push ds
	xor ax, ax
	push ax
	
	mov ax, DATA
	mov ds, ax
	mov pspKeep, es
	
	call memoryFree 
	cmp flag, 0
	je exit
	call path
	call load
	
exit:
	xor al, al
	mov ah, 4ch
	int 21h
begin ENDP

ENDProgram:
CODE ENDS
END begin
