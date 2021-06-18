CODE SEGMENT
	ASSUME CS:CODE, DS:nothing, SS:nothing
	
	MAIN_1 PROC FAR
		push ax
		push dx
		push ds
		push di
		
		mov ax, cs
		mov ds, ax
		mov di, offset ovl_addres
		add di, 43
		call WORD_TO_HEX
		mov dx, offset ovl_addres
		call PRINT_MES
		
		pop di
		pop ds
		pop dx
		pop ax
		retf
	MAIN_1 ENDP

	ovl_addres db 13, 10, "Address of the first overlay module:          ", 13, 10, '$'
	
	PRINT_MES PROC 
		push dx
		push ax
		
		mov ah, 09h
		int 21h

		pop ax
		pop dx
		ret
	PRINT_MES ENDP


	TETR_TO_HEX PROC 
		and al,0fh
		cmp al,09
		jbe next
		add al,07
	next:
		add al,30h
		ret
	TETR_TO_HEX ENDP


	BYTE_TO_HEX PROC		
		push cx
		mov ah, al
		call TETR_TO_HEX
		xchg al,ah
		mov cl,4
		shr al,cl
		call TETR_TO_HEX 	
		pop cx 				
		ret
	BYTE_TO_HEX ENDP


	WORD_TO_HEX PROC  
		push bx
		mov	bh,ah
		call BYTE_TO_HEX
		mov	[di],ah
		dec	di
		mov	[di],al
		dec	di
		mov	al,bh
		xor	ah,ah
		call BYTE_TO_HEX
		mov	[di],ah
		dec	di
		mov	[di],al
		pop	bx
		ret
	WORD_TO_HEX ENDP

CODE ENDS
END MAIN_1 