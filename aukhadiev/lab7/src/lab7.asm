DATA SEGMENT
	firstOVL db "first.ovl", 0
	secondOVL db "second.ovl", 0
	program DW 0	
	memForDTA db 43 DUP(0)
	flagMemory db 0
	posCL db 128 DUP(0)
	addrOVL dd 0
	pspKeep DW 0

	EOF db 0dh, 0ah, '$'
	StringErrorFile db 'Error! File not found!', 0dh, 0ah, '$' 
	StringErrorRoute db 'Error! Route not found!', 0dh, 0ah, '$' 
	StringErrorMCBCrash db 'Error! MCB crashed!', 0dh, 0ah, '$' 
	StringErrorNotEnoughMemory db 'Eror! Not enough memory!', 0dh, 0ah, '$' 
	StringErrorAddr db 'Error! Wrong memory address', 0dh, 0ah, '$'
	
	StringErrorLoadFunction db 'Error! Wrong function!', 0dh, 0ah, '$' 
	StringErrorLoadFiles db 'Error! Too many files were opened!', 0dh, 0ah, '$'
	StringErrorLoadAccess db 'Error! No access!', 0dh, 0ah, '$' 
	StringErrorLoadMemory db 'Error! Wrong memory!', 0dh, 0ah, '$' 
	StringErrorLoadEnv db 'Error! Wrong string of the enviroment ', 0dh, 0ah, '$'
	
    StringFreeMemory db 'Memory was successfully freed' , 0dh, 0ah, '$'
	StringLoadSuccess db  'Loaded successfully', 0dh, 0ah, '$'
	StringMemoryAllocateSuccess db  'Memory was successfully allocated', 0dh, 0ah, '$'
	endData db 0
DATA ENDS

STACK SEGMENT STACK
	DW 128 DUP(?)
STACK ENDS

CODE SEGMENT

ASSUME CS:CODE, DS:DATA, SS:STACK

Output PROC 
 	push ax
 	
 	mov ah, 09h
 	int 21h 
 	
 	pop ax
 	ret
Output ENDP 

MemoryAllocate PROC
	push ax
	push bx
	push cx
	push dx

	push dx 
	mov dx, offset memForDTA
	mov ah, 1ah
	int 21h
	
	pop dx 
	mov cx, 0
	mov ah, 4eh
	int 21h

	jnc AllocateSuccess

AllocateFileError:
	cmp ax, 2
	je AllocateRouteError
	mov dx, offset StringErrorFile
	call Output
	jmp AllocateExit
	
AllocateRouteError:
	cmp ax, 3
	mov dx, offset StringErrorRoute
	call Output
	jmp AllocateExit

AllocateSuccess:
	push di
	mov di, offset memForDTA
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
	
	mov word ptr addrOVL, ax
	mov dx, offset StringMemoryAllocateSuccess
	call Output

AllocateExit:
	pop dx
	pop cx
	pop bx
	pop ax
	ret
MemoryAllocate ENDP

FreeMemory PROC 
	push ax
	push bx
	push cx
	push dx
	
	mov ax, offset endData
	mov bx, offset endProgram
	
	add bx, ax
	mov cl, 4
	shr bx, cl
	add bx, 2bh
	mov ah, 4ah
	int 21h 

	jnc endFreeMemory
	mov flagMemory, 1
	
	cmp ax, 7
	jne ErrorMemory
	mov dx, offset StringErrorMCBCrash
	call Output
	jmp retMemoryFree	
ErrorMemory:
	cmp ax, 8
	jne ErrorAddr
	mov dx, offset StringErrorNotEnoughMemory
	call Output
	jmp retMemoryFree

	
ErrorAddr:
	cmp ax, 9
	mov dx, offset StringErrorAddr
	call Output
	jmp retMemoryFree
	
endFreeMemory:
	mov flagMemory, 1
	mov dx, offset StringFreeMemory
	call Output
	
retMemoryFree:
	pop dx
	pop cx
	pop bx
	pop ax
	ret
FreeMemory ENDP

LoadProc PROC 
	push ax
	push bx
	push cx
	push dx
	push DS
	push es
	
	mov ax, DATA
	mov es, ax
	mov bx, offset addrOVL
	mov dx, offset posCL
	mov ax, 4b03h
	int 21h 
	
	jnc LoadSuccess
	
	cmp ax, 1
	jne LoadErrorFile
	mov dx, offset EOF
	call Output
	
	mov dx, offset StringErrorLoadFunction
	call Output
	jmp LoadErrorExit
	
LoadErrorFile:
	cmp ax, 2
	jne LoadErrorPath
	mov dx, offset StringErrorFile
	call Output
	jmp LoadErrorExit
LoadErrorPath:
	cmp ax, 3
	jne LoadErrorFiles
	mov dx, offset EOF
	call Output
	mov dx, offset StringErrorRoute
	call Output
	jmp LoadErrorExit
LoadErrorFiles:
	cmp ax, 4
	jne LoadErrorAccess
	mov dx, offset StringErrorLoadFiles
	call Output
	jmp LoadErrorExit
LoadErrorAccess:
	cmp ax, 5
	jne LoadErrorMemory
	mov dx, offset StringErrorLoadAccess
	call Output
	jmp LoadErrorExit
LoadErrorMemory:
	cmp ax, 8
	jne LoadErrorEnv
	mov dx, offset StringErrorLoadMemory
	call Output
	jmp LoadErrorExit
LoadErrorEnv:
	cmp ax, 10
	mov dx, offset StringErrorLoadEnv
	call Output
	jmp LoadErrorExit

LoadSuccess:
	mov dx, offset StringLoadSuccess
	call Output
	
	mov ax, word ptr addrOVL
	mov es, ax
	mov word ptr addrOVL, 0
	mov word ptr addrOVL+2, ax

	call addrOVL
	mov es, ax
	mov ah, 49h
	int 21h

LoadErrorExit:
	pop es
	pop DS
	pop dx
	pop cx
	pop bx
	pop ax
	ret
LoadProc ENDP

ProcRoute PROC 
	push ax
	push bx
	push cx 
	push dx
	push di
	push si
	push es
	
	mov program, dx

	mov ax, pspKeep
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
	
RouteLoop:
	mov dl, es:[bx]
	mov byte ptr [posCL+di], dl
	inc di
	inc bx
	cmp dl, 0
	je exitMainRouteLoop
	cmp dl, '\'
	jne RouteLoop
	mov cx, di
	jmp RouteLoop
	
exitMainRouteLoop:
	mov di, cx
	mov si, program
	
ExitFn:
	mov dl, byte ptr [si]
	mov byte ptr [posCL+di], dl
	inc di 
	inc si
	cmp dl, 0 
	jne ExitFn
		
	
	pop es
	pop si
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	ret
ProcRoute ENDP

LoadOVL PROC
	push dx
	
	call ProcRoute
	mov dx, offset posCL
	
	call MemoryAllocate
	call LoadProc
	
	pop dx
	ret
LoadOVL ENDP

Main PROC FAR
	push DS
	xor ax, ax
	push ax
	
	mov ax, DATA
	mov DS, ax
	mov pspKeep, es
	
	call FreeMemory 
	cmp flagMemory, 0
	je exitMain

	mov dx, offset firstOVL
	call LoadOVL
	mov dx, offset EOF
	call Output
	
	mov dx, offset secondOVL
	call LoadOVL

exitMain:
	xor al, al
	mov ah, 4ch
	int 21h
Main ENDP

endProgram:
CODE ENDS
END Main
