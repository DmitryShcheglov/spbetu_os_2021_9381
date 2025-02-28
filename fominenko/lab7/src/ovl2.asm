ASSUME CS:OVL2,DS:OVL2,SS:NOTHING,ES:NOTHING
OVL2 SEGMENT
;---------------------------------------------------------------
MAIN2 PROC FAR 
	push 	ds
	push 	dx
	push 	di
	push 	ax
	mov 	ax,cs
	mov 	ds,ax
	mov 	bx, offset ovl_address
	add 	bx, 18h			
	mov 	di, bx		
	mov 	ax, cs			
	call 	WRD_TO_HEX
	mov 	dx, offset ovl_address	
	call 	PRINT
	pop 	ax
	pop 	di
	pop 	dx	
	pop 	ds
	retf
MAIN2 ENDP

PRINT PROC NEAR  
	push 	ax
	mov 	ah, 09h
	int 	21h
	pop 	ax
	ret
PRINT ENDP

TETR_TO_HEX	PROC near 
	and		al, 0Fh 
	cmp		al, 09 
	jbe		NEXT 
	add		al, 07 
NEXT:
	add	al, 30h 
	ret
TETR_TO_HEX	ENDP

BYTE_TO_HEX	PROC near 
	push	cx
	mov		ah, al 
	call	TETR_TO_HEX 
	xchg	al, ah 
	mov		cl, 4 
	shr		al, cl 
	call	TETR_TO_HEX 
	pop		cx 			
	ret
BYTE_TO_HEX	ENDP

WRD_TO_HEX	PROC near 
	push	bx
	mov		bh, ah 
	call	BYTE_TO_HEX 
	mov		[di], ah 
	dec		di 
	mov		[di], al 
	dec		di
	mov		al, bh 
	xor		ah, ah 
	call	BYTE_TO_HEX 
	mov		[di], ah 
	dec		di
	mov		[di], al 
	pop		bx
	ret
WRD_TO_HEX	ENDP

ovl_address  DB 0DH,0AH, 'Overlay_2 address:                 ',0DH,0AH,'$'

OVL2 ENDS
END