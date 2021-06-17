ASSUME CS:CODE,DS:DATA,SS:LAB_STACK

LAB_STACK    SEGMENT  STACK
          DW 128 DUP(?)   
LAB_STACK    ENDS

DATA SEGMENT 
   nameOverlay1 db 'overlay1.OVL', 0 
   nameOverlay2 db 'overlay2.OVL', 0
   prog dw 0
   dataMem db 43 dup(0)
   pos db 128 dup(0) 
   ovlsAddr dd 0             
   pspKeep dw 0

   eof db 13, 10, '$'
   memoryDestroyed db 'Destroyed memory block',13,10,'$' ;7
   memoryLowMemFunc db 'Not enough memory for running function',13,10,'$' ;8
   memoryWrongMemAdr db 'Incorrect memorys address',13,10,'$' ;9
   
   errorWrongFuncNum  db 'Wrong functions number',13,10,'$' ;1
   errorMissFile  db 'File was not found',13,10,'$' ;2
   errorDisk  db 'Disk error',13,10,'$' ;5
   errorNotEnoughMem  db 'Not enough free disk memory space',13,10,'$' ;8
   errorWrongStrFormat db 'Wrong string enviroment',13,10,'$' ;10
   errorWrongFormat db 'Wrong format',13,10,'$' ;11
   
   endSuccess db 'Normal ending',13,10,'$' ;0
   endCtrlBreak db 'Ending by ctrl-break',13,10,'$' ;1
   endDeviceError db 'Program was ended with device error',13,10,'$' ;2
   endInterruption db 'Program was ended by int 31h interruption',13,10,'$' ;3

   allocateSuccessStr db 'memory allocated successfully', 13, 10, '$'
   errorMissStrFile db 'File not found', 13, 10, '$'
   ERROR_ROUTE db 'Route not found', 13, 10, '$'

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

SET_FULL_FILENAME PROC NEAR
   push ax
   push bx
   push cx
   push dx
   push di
   push si
   push es

   mov prog, dx
   
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
   mov si, prog

LOOP_2:
   mov dl, byte ptr[si]
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
SET_FULL_FILENAME ENDP

DEPLOY_ANOTHER_PROGRAM PROC NEAR
   push ax
   push bx
   push cx
   push dx
   push ds
   push es  

   mov ax, DATA
   mov es, ax
   mov bx, offset ovlsAddr
   mov dx, offset pos
   mov ax, 4b03h
   int 21h 
   
   jnc END_SUCCESS

ERROR_1:
   cmp ax, 1
   jne ERROR_2
   mov dx, offset errorWrongFuncNum
   call PRINT
   jmp DEPLOY_END

ERROR_2:
   cmp ax, 2
   jne ERROR_5
   mov dx, offset errorMissFile
   call PRINT
   jmp DEPLOY_END

ERROR_5:
   cmp ax, 5
   jne ERROR_8
   mov dx, offset errorDisk
   call PRINT
   jmp DEPLOY_END

ERROR_8:
   cmp ax, 8
   jne ERROR_10
   mov dx, offset errorNotEnoughMem
   call PRINT
   jmp DEPLOY_END

ERROR_10:
   cmp ax, 10
   jne ERROR_11
   mov dx, offset errorWrongStrFormat
   call PRINT
   jmp DEPLOY_END

ERROR_11:
   cmp ax, 11
   mov dx, offset errorWrongFormat
   call PRINT
   jmp DEPLOY_END

END_SUCCESS:
   mov dx, offset endSuccess
   call PRINT
   
   mov ax, word ptr ovlsAddr
   mov es, ax
   mov word ptr ovlsAddr, 0
   mov word ptr ovlsAddr + 2, ax

   call ovlsAddr
   mov es, ax
   mov ah, 49h
   int 21h

DEPLOY_END:
   pop es
   pop ds
   pop dx
   pop cx
   pop bx
   pop ax
   ret
DEPLOY_ANOTHER_PROGRAM ENDP

ALLOCATE_MEMORY PROC
   push ax
   push bx
   push cx
   push dx

   push dx
   mov dx, offset dataMem
   mov ah, 1ah
   int 21h
   pop dx
   mov cx, 0
   mov ah, 4eh
   int 21h

   jnc ALLOCATE_SUCCESS

   cmp ax, 2
   je ROUTE_ERR
   mov dx, offset errorMissStrFile
   call PRINT
   jmp ALLOCATE_END

ROUTE_ERR:
   cmp ax, 3
   mov dx, offset ERROR_ROUTE
   call PRINT
   jmp ALLOCATE_END


ALLOCATE_SUCCESS:
   push di
   mov di, offset dataMem
   mov bx, [di + 1ah]
   mov ax, [di + 1ch]
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
   mov word ptr ovlsAddr, ax
   mov dx, offset allocateSuccessStr
   call PRINT

ALLOCATE_END:
   pop dx
   pop cx
   pop bx
   pop ax
   ret
ALLOCATE_MEMORY ENDP

START_OVL PROC
   push dx
   call SET_FULL_FILENAME
   mov dx, offset pos
   call ALLOCATE_MEMORY
   call DEPLOY_ANOTHER_PROGRAM
   pop dx
   ret
START_OVL ENDP

MAIN PROC FAR
   push ds
   xor   ax, ax
   push  ax
   mov   ax, DATA
   mov   ds, ax
   mov pspKeep, es
   call FREE_MEMORY
   mov dx, offset nameOverlay1
   call START_OVL
   mov dx, offset eof
   call PRINT
   mov dx, offset nameOverlay2
   call START_OVL
   
VERY_END:
   xor al,al
   mov ah,4ch
   int 21h
   
MAIN ENDP

END_APP:

CODE ENDS
      END MAIN