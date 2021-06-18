CODE SEGMENT
	ASSUME CS:CODE, DS:DATA, SS:ASTACK 

DATA SEGMENT
    string_wrong_func_num db 'Wrong function number! Error code: 1.', 0DH, 0AH, '$'
	flag db 0
    free_mem_before_error_string db 'Error during free memory before overlay loading! Error code:     h.', 0DH, 0AH, '$'
	alloc_mem_size_error db 'Error during counting overlay size! Error code:      h.', 0DH, 0AH, '$'
    no_file_found_string db 'Error during finding overlay file!', 0DH, 0AH, '$'
	no_route_found_string db 'Error during finding route!', 0DH, 0AH, '$'
	overlay_1_pathway db 'OVERLAY1.OVL',0
    overlay_2_pathway db 'OVERLAY2.OVL',0

    KEEP_PSP dw 0
	DTA db 43 dup (0), '$'
	tmp_over_offset dw  0
    tmp_cur dw 0
    overlay_pathway	db 127h	DUP (0), '$'
	backslash_n_string db 0DH, 0AH, '$'
    over_point dw 0 
	over_start dd 0

	not_existing_func_string db 'Error during loading overlay! Not existing function error!', 0DH, 0AH, '$'
	no_file_found_string2 db 'Error during finding file!', 0DH, 0AH, '$'
	no_route_found_string2 db 'Error during finding route!', 0DH, 0AH, '$'
	too_many_open_files_string db 'Error! Too many opened files there!', 0DH, 0AH, '$'
	access_denied_string db 'Error! Access denied!', 0DH, 0AH, '$'
	not_enough_mem_string db 'Error! Not enough mem to overlay!', 0DH, 0AH, '$'
	wrong_environment_string db 'Error! Wrong environment string!', 0DH, 0AH, '$'
DATA ENDS


;==============================================
OUTPUTTING_STRING_TO_CONSOLE PROC near
	push AX
	mov AH, 09h
	int 21h
	pop AX
	ret
OUTPUTTING_STRING_TO_CONSOLE ENDP
;==============================================
TETR_TO_HEX PROC near
    and AL, 0Fh
    cmp AL, 09
    jbe NEXT
    add AL, 07
NEXT:
    add AL, 30h
    ret
TETR_TO_HEX ENDP
;==============================================
BYTE_TO_HEX PROC near
    push CX
    mov AH, AL
    call TETR_TO_HEX
    xchg AL, AH
    mov CL, 4
    shr AL, CL
    call TETR_TO_HEX
    pop CX
    ret
BYTE_TO_HEX ENDP
;==============================================
WRD_TO_HEX PROC near
    push BX
    mov BH, AH
    call BYTE_TO_HEX
    mov [DI], AH
    dec DI
    mov [DI], AL
    dec DI
    mov AL, BH
    call BYTE_TO_HEX
    mov [DI], AH
    dec DI
    mov [DI], AL
    pop BX
    ret
WRD_TO_HEX ENDP
;==============================================
BYTE_TO_DEC PROC near
    push CX
    push DX
    xor AH, AH
    xor DX, DX
    mov CX, 10
loop_bd:
    div CX     
    or DL, 30h
    mov [SI], DL
    dec SI
    xor DX, DX
    cmp AX, 10
    jae loop_bd
    cmp AL, 00h
    je end_l
    or AL, 30h
    mov [SI], AL
end_l:
    pop DX
    pop CX
    ret    
BYTE_TO_DEC ENDP
;==============================================
FREE_MEM_BEFORE PROC near
    push AX
	push DX
	push BX

	mov AX, ASTACK
	mov BX, ES
	sub AX, BX
	add	AX, 100h
	mov BX, AX
	mov AH, 4Ah
	int 21h

	jnc good_end
	mov flag, 1
		
	mov DI, offset free_mem_before_error_string
	add DI, 62
	call WRD_TO_HEX
	mov DX, offset free_mem_before_error_string
	call OUTPUTTING_STRING_TO_CONSOLE

	pop BX
	pop DX
	pop AX

	xor	AL,AL
	mov	AH,4CH
	int 21h

good_end:
	pop BX
	pop DX
	pop AX
	ret
FREE_MEM_BEFORE ENDP
;==============================================
WRITE_PATHWAY PROC near
    push AX
	push CX
	push DX

    mov tmp_over_offset, AX
    mov ES, KEEP_PSP
	mov ES, ES:[2Ch]
	xor SI, SI

starting:
	mov AX, ES:[SI]
	inc	SI
	cmp AX, 0
	jne starting
	add SI, 3   
	mov DI, 0
	mov DI, offset overlay_pathway

writing:
	mov AL, ES:[SI]
	cmp AL, 0
	je program_name     

	cmp AL, '\'
	jne write_to_path
	mov tmp_cur, DI

write_to_path:
	mov [DI], AL
	inc DI
	inc SI
	jmp writing

program_name:
	mov DI, tmp_cur               
	inc DI
	mov SI, tmp_over_offset
	mov CX, 5

loop_writing:
	mov DL, [SI]
	mov [DI], DL
	inc SI
	inc DI
	cmp DL, 0
	jne loop_writing

	mov DX, offset overlay_pathway
	call OUTPUTTING_STRING_TO_CONSOLE

	mov DX, offset backslash_n_string
	call OUTPUTTING_STRING_TO_CONSOLE

	pop DX
	pop CX
	pop AX
	ret
WRITE_PATHWAY ENDP
;==============================================
COUNT_OVERLAY_SIZE PROC near
	push BX
	push ES

	mov AX, 1A00h
	mov DX, offset DTA
	int 21h

	mov AL, 0
	mov	AH, 4Eh
	mov CX, 0
	mov DX, offset overlay_pathway
	int 21h

	jnc SUCCESS_SIZE
	mov flag, 1

	cmp AX, 2
	je no_file_found
	cmp AX, 3
	je no_route_found

no_file_found:
	mov DX, offset no_file_found_string
	call OUTPUTTING_STRING_TO_CONSOLE
	jmp good_ending

no_route_found:
	mov DX, offset no_route_found_string
	call OUTPUTTING_STRING_TO_CONSOLE
	jmp good_ending

SUCCESS_SIZE:

	mov SI, offset DTA
	add SI, 1AH
	
	mov BX, [SI]
	mov CL, 4
	shr BX, CL      

	mov AX, [SI+2]
	mov CL, 12
	shl AX, CL

	add BX, AX
	add BX, 2
	mov AL, 0
	mov AH, 48H
	int 21h
	jnc SUCCESS_DTA
	mov flag, 1
	jmp good_ending
		
	mov DI, offset alloc_mem_size_error
	add DI, 50
	call WRD_TO_HEX
	mov DX, offset alloc_mem_size_error
	call OUTPUTTING_STRING_TO_CONSOLE
	jmp good_ending

SUCCESS_DTA:
	mov	over_point, AX

good_ending:
	pop ES
	pop BX
	ret
COUNT_OVERLAY_SIZE ENDP
;==============================================
OVERLAY_LOADING PROC near
	push AX
	push DX
	push ES

	mov AX, DS
	mov ES, AX
	mov BX, offset over_point

	mov DX, offset overlay_pathway
	mov AX, 4B03H
	int 21h

	jnc SUCCESS_LOAD
	mov flag, 1

	cmp AX, 1
	je not_existing_func
	cmp AX, 2
	je no_file_founded
	cmp AX, 3
	je no_route
	cmp AX, 4
	je too_many_open_files
	cmp AX, 5
	je access_denied
	cmp AX, 8
	je not_enough_mem
	cmp AX, 10
	je wrng_env

not_existing_func:
	mov DX, offset not_existing_func_string
	call OUTPUTTING_STRING_TO_CONSOLE
	jmp	END_LOAD

no_file_founded:
	mov DX, offset no_route_found_string2
	call OUTPUTTING_STRING_TO_CONSOLE
	jmp	END_LOAD
	
no_route:
	mov DX, offset no_route_found_string2
	call OUTPUTTING_STRING_TO_CONSOLE
	jmp	END_LOAD

too_many_open_files:
	mov DX, offset too_many_open_files_string
	call OUTPUTTING_STRING_TO_CONSOLE
	jmp	END_LOAD

access_denied:
	mov DX, offset access_denied_string
	call OUTPUTTING_STRING_TO_CONSOLE
	jmp	END_LOAD

not_enough_mem:
	mov DX, offset not_enough_mem_string
	call OUTPUTTING_STRING_TO_CONSOLE
	jmp	END_LOAD

wrng_env:
	mov DX, offset wrong_environment_string
	call OUTPUTTING_STRING_TO_CONSOLE
	jmp	END_LOAD

SUCCESS_LOAD:
	mov AX, over_point
	mov ES, AX

	mov word ptr over_start + 2, AX
	call over_start
	mov ES, AX
	xor AL, AL
	mov AH, 49H
	int 21h

END_LOAD:
	pop ES
	pop DX
	pop AX
	ret
OVERLAY_LOADING ENDP
;==============================================
Main PROC FAR
	push DS
	xor	AX, AX
	push AX
	mov AX, DATA
	mov DS, AX
	mov KEEP_PSP, ES

    call FREE_MEM_BEFORE
    cmp flag, 1
    je real_end
;loading first overlay
    mov AX, offset overlay_1_pathway
    call WRITE_PATHWAY
    call COUNT_OVERLAY_SIZE
    cmp flag, 1
	je real_end
    call OVERLAY_LOADING
	cmp flag, 1
	je real_end

;loading second overlay
    mov AX, offset overlay_2_pathway
    call WRITE_PATHWAY
    call COUNT_OVERLAY_SIZE
    cmp flag, 1
	je real_end
    call OVERLAY_LOADING

real_end:
    xor AL, AL
	mov AH, 4Ch
	int 21h
Main ENDP
CODE ENDS

ASTACK SEGMENT STACK
    dw 64 DUP(?)   
ASTACK ENDS

    END Main