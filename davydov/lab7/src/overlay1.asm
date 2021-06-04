OVL1 SEGMENT
	ASSUME CS:OVL1, DS:NOTHING, SS:NOTHING
	MAIN PROC FAR
		push ax
		push dx
		push ds
		push di
      
		mov ax, cs
		mov ds, ax
		mov di, offset OvlAddr
		add di, 23
		call WRD_TO_HEX
		mov dx, offset OvlAddr
		call PRINT
      
		pop di
		pop ds
		pop dx
		pop ax
		retf
	MAIN endp

	OvlAddr db 13, 10, "OVL1 address:          ", 13, 10, '$'
   
	PRINT PROC 
		push dx
		push ax
		mov ah, 09h
		int 21h
		pop ax
		pop dx
		ret
	PRINT ENDP


	TETR_TO_HEX PROC 
		and al,0fh
		cmp al,09
		jbe NEXT
		add al,07
	NEXT:
		add al,30h
		ret
	TETR_TO_HEX ENDP


	BYTE_TO_HEX PROC     
		push  cx
		mov   ah, al
		call  TETR_TO_HEX
		xchg  al,ah
		mov   cl,4
		shr   al,cl
		call  TETR_TO_HEX   
		pop   cx             
		ret
	BYTE_TO_HEX ENDP


	WRD_TO_HEX PROC
		push  bx
		mov   bh,ah
		call  BYTE_TO_HEX
		mov   [di],ah
		dec   di
		mov   [di],al
		dec   di
		mov   al,bh
		xor   ah,ah
		call  BYTE_TO_HEX
		mov   [di],ah
		dec   di
		mov   [di],al
		pop   bx
		ret
	WRD_TO_HEX ENDP

OVL1 ENDS
END MAIN 