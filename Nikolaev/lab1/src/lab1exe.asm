AStack    SEGMENT  STACK
          DW 100 DUP(1)    
AStack    ENds


DATA      SEGMENT

TYPEPC db 'PC: $'
PC db 'PC', 13,10,'$'
PC_TYPE_XT db 'PC/XT', 13,10,'$'
PC_TYPE_AT db 'AT$', 13,10,'$'
PC_TYPE_30 db 'PS2 (30 model)', 13,10,'$'
PC_TYPE_5060 db 'PS2 (50 or 60 model)', 13,10,'$'
PC_TYPE_80 db 'PS2 (80 model)', 13,10,'$'
PC_TYPE_JR db 'PC jr', 13,10,'$'
PC_TYPE_CONVERTIBLE db 'PC Convertible', 13,10,'$'

DOT db '.$'
VERSION db 13, 10, 'SYSTEM VERSION: $'
OEM db 13, 10, 'OEM: $'
USER db 13, 10, 'SERIAL USER NUMBER: $'

DATA      ENds

CODE      SEGMENT
          ASSUME CS:CODE, ds:DATA, SS:AStack

PRINT	  PROC  NEAR
          mov   ah,9
          int   21h 
          ret
PRINT     ENDP

OutInt proc near
    xor     cx, cx
    mov     bx, dx 
oi2:
    xor     dx,dx
    div     bx
    push    dx
    inc     cx
    cmp    ax, ax
    jnz     oi2
    mov     ah, 02h
oi3:
    pop     dx
    cmp     dl,9
    jbe     oi4
    add     dl,7

oi4:
    add     dl, '0'
    int     21h
    loop    oi3
    ret

OutInt endp

Main      PROC  FAR
		push  ds       
        sub   ax,ax    
        push  ax       
        mov   ax,DATA             
        mov   ds,ax               
		mov		dx, OFFSET TYPEPC
		call 	PRINT
		mov 	ax, 0F000h
		mov		ES, ax
		mov 	ax, 0
		mov 	al, ES:[0FFFEh]
		cmp 	al, 0FFh
		jz 		PCLABEL
		cmp 	al, 0FEh
		jz 		PC_TYPE_XTLABEL
		cmp 	al, 0FBh
		jz 		PC_TYPE_XTLABEL
		cmp 	al, 0FCh
		jz 		PC_TYPE_ATLABEL
		cmp 	al, 0FAh
		jz 		PC_TYPE_30LABEL
		cmp 	al, 0FCh
		jz 		PC_TYPE_5060LABEL
		cmp 	al, 0F8h
		jz 		PC_TYPE_80LABEL
		cmp 	al, 0FDh
		jz 		PC_TYPE_JRLABEL
		cmp 	al, 0F9h
		jz 		PC_TYPE_CONVERTIBLELABEL
		jmp 	UNKNOWN_TYPE_LABEL	
PCLABEL:
		mov 	dx, OFFSET PC
		jmp 	PCTYPE_OUT
PC_TYPE_XTLABEL:		
		mov 	dx, OFFSET PC_TYPE_XT
	    jmp 	PCTYPE_OUT
PC_TYPE_ATLABEL:
		mov 	dx, OFFSET PC_TYPE_AT
		jmp 	PCTYPE_OUT
PC_TYPE_30LABEL:
		mov 	dx, OFFSET PC_TYPE_30
		jmp 	PCTYPE_OUT
PC_TYPE_5060LABEL:
		mov 	dx, OFFSET PC_TYPE_5060
		jmp 	PCTYPE_OUT
PC_TYPE_80LABEL:
		mov 	dx, OFFSET PC_TYPE_80
		jmp 	PCTYPE_OUT
PC_TYPE_JRLABEL:
		mov 	dx, OFFSET PC_TYPE_JR
		jmp 	PCTYPE_OUT
PC_TYPE_CONVERTIBLELABEL:
		mov 	dx, OFFSET PC_TYPE_CONVERTIBLE
		jmp 	PCTYPE_OUT
UNKNOWN_TYPE_LABEL:
		mov		dx, 16
		call 	OutInt
		jmp		MSDOS_VERSION
PCTYPE_OUT:
		call 	PRINT
MSDOS_VERSION:	
		mov 	ah,30h       
		int 	21h
		push 	cx
		push 	bx
		push 	ax
		mov		dx, OFFSET VERSION
		call 	PRINT
		mov 	ax, 0
		pop 	ax 	
		push 	ax  
		mov 	ah, 0
		mov 	dx, 10
		call 	OutInt
		mov		dx, OFFSET DOT
		call 	PRINT
		pop 	ax
		mov 	ah, ch
		mov 	ah, 0
		mov 	al, ch
		mov 	dx, 10
		call 	OutInt
		mov		dx, OFFSET OEM
		call 	PRINT
		pop 	ax
		push 	ax
		mov 	ah, ch
		mov 	ah, 0
		mov 	al, ch
		mov 	dx, 10
		call 	OutInt
		mov		dx, OFFSET USER
		call 	PRINT
		pop 	ax
		mov 	ah, 0
		cmp 	al, 0
		jz 		NEXT_NUMBER
		mov 	dx, 10
		call 	OutInt
NEXT_NUMBER:
		pop 	ax
		mov 	dx, 10
		call 	OutInt
		ret
Main      ENDP
CODE      ENds
          END Main