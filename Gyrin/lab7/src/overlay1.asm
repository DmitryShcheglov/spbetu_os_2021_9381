CODE 				SEGMENT
					ASSUME 	cs:CODE, ds:nothing, ss:nothing
MAIN 	PROC far
					push 	ax
					push 	dx
					push 	ds
					push 	di
		
					mov 	ax, cs
					mov 	ds, ax
					mov 	di, offset ovl
					add 	di, 23
					call	wrd_to_hex
					mov 	dx, offset ovl
					call 	print
		
					pop 	di
					pop 	ds
					pop 	dx
					pop 	ax
					retf
	MAIN 			ENDP

	ovl 			db 		13, 10, "ovl_1 address:          ", 13, 10, '$'
	
print	 			PROC 
					push 	dx
					push 	ax
		
					mov 	ah, 09h
					int 	21h

					pop 	ax
					pop 	dx
					ret
print 				ENDP


tetr_to_hex 		PROC 
					and 	al,0fh
					cmp 	al,09
					jbe 	next
					add 	al,07
			next:
					add 	al,30h
					ret
tetr_to_hex 		ENDP


byte_to_hex 		PROC		
					push 	cx
					mov 	ah, al
					call 	tetr_to_hex
					xchg 	al,ah
					mov 	cl,4
					shr 	al,cl
					call 	tetr_to_hex 	
					pop 	cx 				
					ret
byte_to_hex 		ENDP


wrd_to_hex 			PROC  
					push	bx
					mov		bh,ah
					call	byte_to_hex
					mov		[di],ah
					dec		di
					mov		[di],al
					dec		di
					mov		al,bh
					xor		ah,ah
					call	byte_to_hex
					mov		[di],ah
					dec		di
					mov		[di],al
					pop		bx
					ret
wrd_to_hex 			ENDP

CODE 				ENDS
					end 	MAIN 