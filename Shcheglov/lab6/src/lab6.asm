CODE SEGMENT
	ASSUME CS:CODE, DS:DATA, SS:ASTACK 
;==============================================
OUTPUTTING_STRING_TO_CONSOLE PROC near
	push AX
	mov AH, 09h
	int 21h
	pop AX
	ret
OUTPUTTING_STRING_TO_CONSOLE ENDP
;==============================================
OUTPUTTING_CHAR_TO_CONSOLE PROC near
	push AX
	mov AH, 02h
	int 21h
	pop AX
	ret
OUTPUTTING_CHAR_TO_CONSOLE ENDP
;==============================================
FUNCTION_WITH_ERRORS PROC near
	push AX

	cmp AX, 1h
	je func_num_er
	cmp AX, 2h
	je no_file
	cmp AX, 5h
	je disk_er
	cmp AX, 8h
	je no_en_mem
	cmp AX, 10h
	je wrong_env_string
	cmp AX, 11h
	je wr_format

func_num_er:
	mov DX, offset string_wrong_func_num
	call OUTPUTTING_STRING_TO_CONSOLE
	jmp pro_end

no_file:
	mov DX, offset string_no_file
	call OUTPUTTING_STRING_TO_CONSOLE
	jmp pro_end

disk_er:
	mov DX, offset string_disk_error
	call OUTPUTTING_STRING_TO_CONSOLE
	jmp pro_end

no_en_mem:
	mov DX, offset string_not_enough_mem
	call OUTPUTTING_STRING_TO_CONSOLE
	jmp pro_end

wrong_env_string:
	mov DX, offset string_wrong_env_string
	call OUTPUTTING_STRING_TO_CONSOLE
	jmp pro_end

wr_format:
	mov DX, offset string_wrong_format
	call OUTPUTTING_STRING_TO_CONSOLE
	jmp pro_end

pro_end:
	pop AX
	ret
FUNCTION_WITH_ERRORS ENDP
;==============================================
FUNC_WITH_ERRORS_1 PROC near
	push AX

	cmp AX, 7h
	je dest_mem_block
	cmp AX, 8h
	je not_enouth_mem
	cmp AX, 9h
	je wrong_address

dest_mem_block:
	mov DX, offset string_mem_block_destroed
	call OUTPUTTING_STRING_TO_CONSOLE
	jmp pr_end

not_enouth_mem:
	mov DX, offset string_not_enough_mem_to_func
	call OUTPUTTING_STRING_TO_CONSOLE
	jmp pr_end

wrong_address:
	mov DX, offset string_wrong_block_addr
	call OUTPUTTING_STRING_TO_CONSOLE
	jmp pr_end

pr_end:
	pop AX
	ret
FUNC_WITH_ERRORS_1 ENDP
;==============================================
BYTE_TO_DEC PROC near
; перевод в 10c/c, SI - адрес поля младшей цифры
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
Main PROC FAR
	push DS
	xor	AX, AX
	push AX
	mov AX, DATA
	mov DS, AX
	mov PSP, ES

	mov BX, offset module_code_seg
	add BX, offset module_data_seg
	add BX, 30Fh 
	mov CL, 4h 
	shr BX, CL 
	inc BX 
	mov AX, 4A00h 
	int 21H
	jnc free_mem
	call FUNC_WITH_ERRORS_1
	jmp real_end

free_mem:
	mov AX, PSP 
	mov ES, AX 
	mov ES, ES:[2CH] 
	mov SI, 0 
zero_in_path:
	mov AX, ES:[SI] 
	inc SI 
	cmp AX, 0 
	jne zero_in_path
	add SI, 3 
	mov DI, 0
writing_path_to_console: 
	mov AL, ES:[SI] 
	cmp AL, 0 
	je full_programm_path
	cmp AL, '\' 
	jne add_char 
	mov KEEP_DI, DI 
add_char:
	mov byte ptr[system_path + DI], AL 
	inc SI 
	inc DI 
	jmp writing_path_to_console	
full_programm_path:
	CLD 
	mov DI, KEEP_DI 
	inc DI 
	add DI, offset system_path 
	mov SI, offset program_name
	mov AX, DS 
	mov ES, AX 
write_full_programm_path: 
	LODSB 
	STOSB
	cmp AL, 0 
	jne write_full_programm_path 

	push DS 
	push ES 
	mov	KEEP_SP, SP 
	mov KEEP_SS, SS 
		
	mov AX, ES:[2CH] 
	mov block_of_params, AX 
	mov block_of_params + 2, ES 
	mov block_of_params + 4, 80H
	
	mov AX, DATA 
	mov ES, AX 
		
	mov BX, offset block_of_params
	mov DX, offset system_path
	mov AX, 4B00H 
	int 21H 
		
	mov BX, AX 
	mov AX, DATA 
	mov DS, AX 
	mov AX, BX 
	mov SS, KEEP_SS
	mov SP, keep_SP
	POP ES 
	POP DS 
	
	jnc load_successful
	call FUNCTION_WITH_ERRORS	
	JMP real_end

load_successful:
	mov AX, 4D00H 
	int 21H

	mov DX, offset string_termination
	call OUTPUTTING_STRING_TO_CONSOLE
	
	cmp AH, 0H
	je normal_return

	cmp AH, 1h
	je ctrl_and_c

	cmp AH, 2h
	je device_error

	cmp AH, 3h
	je res_prog

normal_return:
	mov DX, offset string_normal_termination
	call OUTPUTTING_STRING_TO_CONSOLE
	mov DL, AL
	mov SI, offset string_termination_code
	add SI, 24
	call BYTE_TO_DEC
	mov DX, offset string_termination_code
	call OUTPUTTING_STRING_TO_CONSOLE
	mov DX, offset dop_string
	call OUTPUTTING_STRING_TO_CONSOLE
	jmp real_end

ctrl_and_c:
	mov DX, offset string_ctrl_break
	call OUTPUTTING_STRING_TO_CONSOLE
	mov DL, AL
	mov SI, offset string_termination_code
	add SI, 24
	call BYTE_TO_DEC
	mov DX, offset string_termination_code
	call OUTPUTTING_STRING_TO_CONSOLE
	mov DX, offset dop_string
	call OUTPUTTING_STRING_TO_CONSOLE
	jmp real_end


device_error:
	mov DX, offset string_dev_error
	call OUTPUTTING_STRING_TO_CONSOLE
	mov DL, AL
	mov SI, offset string_termination_code
	add SI, 24
	call BYTE_TO_DEC
	mov DX, offset string_termination_code
	call OUTPUTTING_STRING_TO_CONSOLE
	mov DX, offset dop_string
	call OUTPUTTING_STRING_TO_CONSOLE
	jmp real_end


res_prog:
	mov DX, offset string_let_res
	call OUTPUTTING_STRING_TO_CONSOLE
	mov DL, AL
	mov SI, offset string_termination_code
	add SI, 24
	call BYTE_TO_DEC
	mov DX, offset string_termination_code
	call OUTPUTTING_STRING_TO_CONSOLE
	mov DX, offset dop_string
	call OUTPUTTING_STRING_TO_CONSOLE
	jmp real_end

real_end:
	mov AX, 4C00H
	int 21H
module_code_seg:
Main ENDP
CODE ENDS

ASTACK SEGMENT STACK
    dw 64 DUP(?)   
ASTACK ENDS

DATA SEGMENT
	PSP dw 0H
	string_wrong_func_num db 'Wrong function number! Error code: 1.', 0DH, 0AH, '$'
	string_no_file db 'Could not find file! Error code: 2.', 0DH, 0AH, '$'
	string_disk_error db 'Drive error! Error code: 5.', 0DH, 0AH, '$'
	string_not_enough_mem db 'Not enough memory! Error code: 8.', 0DH, 0AH, '$'
	string_wrong_env_string db 'Wrong enviroments string! Error code: 10.', 0DH, 0AH, '$'
	string_wrong_format db 'Wrong format! Error code 11.', 0DH, 0AH, '$'
	string_mem_block_destroed db 'Manage memory block has been destroyes! Error code: 7.', 0DH, 0AH, '$'
	string_not_enough_mem_to_func db 'Not enough memory to do function! Error code: 8.', 0DH, 0AH, '$'
	string_wrong_block_addr db 'Wrong memory block address!. Error code: 9.', 0DH, 0AH, '$'
	string_termination db 'Program was terminated:', 0DH, 0AH, '$'
	string_normal_termination db 'Program was normally terminated (Code 0).', 0DH, 0AH, '$'
	string_ctrl_break db 'Program was terminated by ctrl-break (Code 1).', 0DH, 0AH, '$'
	string_dev_error db 'Program was terminated by device error (Code 2)', 0DH, 0AH, '$'
	string_let_res db 'Program was terminated by function 31h (Code 3)', 0DH, 0AH, '$'
	string_termination_code db 'Termination code is: [   $'
	string_backslash_n db 0DH, 0AH, '$'
	dop_string db ']', 0DH, 0AH, '$'
	filename db 50 dup(0)
	param dw 7 dup(?)

	block_of_params dw 0 ;сегментный адрес среды
		dd 0 ;сегмент и смещение командной строки
		dd 0 ;сегмент и смещение первого FCB
		dd 0 ;сегмент и смещение второго FCB

	system_path db 127H DUP(0)
	program_name db 'lab2.com',0
	
	KEEP_DI dw 0H 
	KEEP_SS dw 0H 
	KEEP_SP dw 0H 

	module_data_seg db 0
DATA ENDS
    END Main