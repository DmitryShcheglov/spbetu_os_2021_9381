CODE SEGMENT
	ASSUME CS:CODE, DS:nothing, SS:nothing
	
	Main PROC FAR
		push ax
		push dx
		push ds
		push di
		
		mov ax, cs
		mov ds, ax
		mov di, offset StringOVL
		add di, 25
		call wrd_to_hex
		mov dx, offset StringOVL
		call Output
		
		pop di
		pop ds
		pop dx
		pop ax
		retf
	Main ENDP

	StringOVL db 13, 10, "second ovl address:           ", 13, 10, '$'
	
	Output PROC 
		push dx
		push ax
		
		mov ah, 09h
		int 21h

		pop ax
		pop dx
		ret
	Output ENDP


	tetr_to_hex PROC 
		and al,0fh
		cmp al,09
		jbe next
		add al,07
	next:
		add al,30h
		ret
	tetr_to_hex ENDP


	byte_to_hex PROC		
		push cx
		mov ah, al
		call tetr_to_hex
		xchg al,ah
		mov cl,4
		shr al,cl
		call tetr_to_hex 	
		pop cx 				
		ret
	byte_to_hex ENDP


	wrd_to_hex PROC  
		push bx
		mov	bh,ah
		call byte_to_hex
		mov	[di],ah
		dec	di
		mov	[di],al
		dec	di
		mov	al,bh
		xor	ah,ah
		call byte_to_hex
		mov	[di],ah
		dec	di
		mov	[di],al
		pop	bx
		ret
	wrd_to_hex ENDP

CODE ENDS
END Main
