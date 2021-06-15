DATA SEGMENT
	psp dw 0

	OVL_PARAM_SEG 			dw 0
	OVL_ADRESS 				dd 0

	mem_cl_str				db 13,10, "Cleared memory$"
	size_error_str 		db 13, 10, "Can't get overlay size$"
	no_file_str 				db 13, 10, "No overlay file$"
	no_path_str 				db 13, 10, "Can't find path$"
	load_error_str 			db 13, 10, "Overlay wasn't load$"
	ovl1_str 				db "ovl1.ovl", 0
	ovl2_str 				db "ovl2.ovl", 0
	STR_PATH 				db 100h dup(0)
	OFFSET_OVL_NAME 		dw 0
	NAME_POS 				dw 0
	MEMORY_ERROR 			dw 0
	
	DTA 					db 43 dup(0)
DATA ENDS

STACKK SEGMENT STACK
	dw 100h dup (0)
STACKK ENDS

CODE SEGMENT
	ASSUME CS:CODE, DS:DATA, SS:STACKK

WriteString 	PROC	near
		push 	AX
		mov 	AH, 09h
		int		21h
		pop 	AX
	ret
WriteString 	ENDP

FreeMem 	PROC
		lea 	bx, progend
		mov 	ax, es
		sub 	bx, ax
		mov 	cl, 8
		shr 	bx, cl
		sub 	ax, ax
		mov 	ah, 4ah
		int 	21h
		jc 		mcatch
		mov dx, offset mem_cl_str
		call WriteString
		jmp 	mdefault
	mcatch:
		mov 	memory_error, 1
	MDEFAULT:
	ret
FreeMem 	ENDP


OVL_RUN PROC
		push	AX
		push	BX
		push	CX
		push	DX
		push	SI

		mov 	offset_ovl_name, ax
		mov 	ax, psp
		mov 	es, ax
		mov 	es, es:[2ch]
		mov 	si, 0
	find_zero:
		mov 	ax, es:[si]
		inc 	si
		cmp 	ax, 0
		jne 	find_zero
		add 	si, 3
		mov 	di, 0
	write_path:
		mov 	al, es:[si]
		cmp 	al, 0
		je 		write_path_name
		cmp 	al, '\'
		jne 	new_symb
		mov 	name_pos, di
	new_symb:
		mov 	byte ptr [str_path + di], al
		inc 	di
		inc 	si
		jmp 	write_path
	write_path_name:
		cld
		mov 	di, name_pos
		inc 	di
		add 	di, offset str_path
		mov 	si, offset_ovl_name
		mov 	ax, ds
		mov 	es, ax
	update:
		lodsb
		stosb
		cmp 	AL, 0
		jne 	UPDATE

		mov 	AX, 1A00h
		mov 	DX, offset DTA
		int 	21h
		
		mov 	AH, 4Eh
		mov 	CX, 0
		mov 	DX, offset STR_PATH
		int 	21h
		
		jnc 	NOERROR
		mov 	DX, offset size_error_str
		call 	WriteString
		cmp 	AX, 2
		je 		NOFILE
		cmp 	AX, 3
		je 		NOPATH
		jmp 	PATH_ENDING
	nofile:
		mov 	dx, offset no_file_str
		call 	WriteString
		jmp 	PATH_ENDING
	nopath:
		mov 	dx, offset no_path_str
		call 	WriteString
		jmp 	path_ending
	noerror:
		mov 	SI, offset DTA
		add 	si, 1ah
		mov 	bx, [si]
		mov 	ax, [si + 2]
		mov		cl, 4
		shr 	bx, cl
		mov		cl, 12
		shl 	ax, cl
		add 	bx, ax
		add 	bx, 2
		mov 	ax, 4800h
		int 	21h
		
		jnc 	set_seg
		jmp 	path_ending
	set_seg:
		mov 	ovl_param_seg, ax
		mov 	dx, offset str_path
		push 	ds
		pop 	es
		mov 	bx, offset ovl_param_seg
		mov 	ax, 4b03h
		int 	21h
		
		jnc 	LO_SUCCESS		
		mov 	DX, offset load_error_str
		call 	WriteString
		jmp		path_ending

	lo_success:
		mov		ax, ovl_param_seg
		mov 	es, ax
		mov 	word ptr ovl_adress + 2, ax
		call 	ovl_adress
		mov 	es, ax
		mov 	ah, 49h
		int 	21h

	path_ending:
		pop 	si
		pop 	dx
		pop 	cx
		pop 	bx
		pop 	ax
		ret
	ovl_run ENDP
	
	BEGIN:
		mov 	AX, DATA
		mov 	DS, AX
		mov 	psp, ES
		call 	FreeMem
		cmp 	memory_error, 1
		je 		main_end
		mov 	ax, offset ovl1_str
		call 	ovl_run
		mov 	ax, offset ovl2_str
		call 	ovl_run
		
	main_end:
		mov ax, 4c00h
		int 21h
	progend:
code ends
end begin