MyStack    SEGMENT  STACK
          DW 64 DUP(?)   
MyStack    ENDS

CODE SEGMENT
   ASSUME CS:CODE,DS:DATA,SS:MyStack

my_interruption PROC FAR
	jmp start_f

	PSP_address_0 dw 0
	PSP_address_1 dw 0
	keep_CS dw 0
	keep_IP dw 0
	my_interruption_set dw 0FEDCh
	int_count db 'Interrupts call count: 0000  $'

start_f:
	push ax
	push bx
	push cx
	push dx

	mov ah, 03h
	mov bh, 00h
	int 10h
	push dx
	mov ah, 02h
	mov bh, 00h
	mov dx, 0220h
	int 10h 
	push si
	push cx
	push ds
	mov ax, SEG int_count
	mov ds, ax
	mov si, offset int_count
	add si, 1Ah
	mov ah,[si]
	inc ah
	mov [si], ah
	cmp ah, 3Ah
	jne end_cal
	mov ah, 30h
	mov [si], ah

	mov bh, [si - 1]
	inc bh
	mov [si - 1], bh
	cmp bh, 3Ah
	jne end_cal
	mov bh, 30h
	mov [si - 1], bh

	mov ch, [si - 2]
	inc ch
	mov [si - 2], ch
	cmp ch, 3Ah
	jne end_cal
	mov ch, 30h
	mov [si - 2], ch

	mov dh, [si - 3]
	inc dh
	mov [si - 3], dh
	cmp dh, 3Ah
	jne end_cal
	mov dh, 30h
	mov [si - 3],dh

end_cal:
    pop ds
    pop cx
	pop si

	push es
	push bp
	mov ax, SEG int_count
	mov es, ax
	mov ax, offset int_count
	mov bp, ax
	mov ah, 13h
	mov al, 00h
	mov cx, 1Dh
	mov bh, 0
	int 10h
	pop bp
	pop es

	pop dx
	mov ah, 02h
	mov bh, 0h
	int 10h

	pop dx
	pop cx
	pop bx
	pop ax

	iret
my_interruption ENDP

mem_pool PROC
mem_pool ENDP

is_inter_set PROC NEAR
	push bx
	push dx
	push es

	mov ah, 35h
	mov al, 1Ch
	int 21h

	mov dx, es:[bx + 11]
	cmp dx, 0FEDCh
	je is_set
	mov al, 00h
	jmp pop_reg

is_set:
	mov al, 01h
	jmp pop_reg

pop_reg:
	pop es
	pop dx
	pop bx

	ret
is_inter_set ENDP

check_com_promt PROC NEAR
	push es

	mov ax, PSP_address_0
	mov es, ax
	mov bx, 0082h

	mov al, es:[bx]
	inc bx
	cmp al, '/'
	jne null_cmd
	mov al, es:[bx]
	inc bx
	cmp al, 'u'
	jne null_cmd
	mov al, es:[bx]
	inc bx
	cmp al, 'n'
	jne null_cmd

	mov al, 0001h
null_cmd:
	pop es

	ret
check_com_promt ENDP

load_inter PROC NEAR
	push ax
	push bx
	push dx
	push es

	mov ah, 35h
	mov al, 1Ch
	int 21h

	mov keep_IP, bx
	mov keep_CS, es

	push ds
	mov dx, offset my_interruption
	mov ax, seg my_interruption
	mov ds, ax
	mov ah, 25h
	mov al, 1Ch
	int 21h
	pop ds

	mov dx, offset InterraptionLoading
	call print_string
	pop es
	pop dx
	pop bx
	pop ax

	ret
load_inter ENDP

unload_inter PROC NEAR
	push ax
	push bx
	push dx
	push es

	mov ah, 35h
	mov al, 1Ch
	int 21h
	cli
	push ds
	mov dx, es:[bx + 9]
	mov ax, es:[bx + 7]
	mov ds, ax
	mov ah, 25h
	mov al, 1Ch
	int 21h
	pop ds
	sti

	mov dx, offset InterruptionRestored
	call print_string

	push es
	mov cx, es:[bx + 3]
	mov es, cx
	mov ah, 49h
	int 21h
	pop es

	mov cx, es:[bx + 5]
	mov es, cx
	int 21h
	pop es
	pop dx
	pop bx
	pop ax

	ret
unload_inter ENDP

print_string PROC NEAR
	push ax
	mov ah, 09h
	int	21h
	pop ax
	ret
print_string ENDP

Main PROC FAR
	mov bx, 02Ch
	mov ax, [bx]
	mov PSP_address_1, ax
	mov PSP_address_0, ds
	sub ax, ax
	sub bx, bx

	mov ax, DATA
	mov ds, ax

	call check_com_promt
	cmp al, 01h
	je unload_start

	call is_inter_set
	cmp al, 01h
	jne inter_isnt_loaded

	mov dx, offset InterruptionLoaded
	call print_string
	jmp exit_f
	mov ah,4Ch
	int 21h

inter_isnt_loaded:
	call load_inter

	mov dx, offset mem_pool
	mov cl, 04h
	shr dx, cl
	add dx, 1Bh
	mov ax, 3100h
	int 21h

unload_start:
	call is_inter_set
	call unload_inter
	jmp exit_f

exit_f:
	mov ah, 4Ch
	int 21h
Main ENDP
CODE ENDS
DATA  SEGMENT

	InterruptionRestored db "InterruptionRestored", 0dh, 0ah, '$'
	InterruptionLoaded db "InterruptionLoaded", 0dh, 0ah, '$'
	InterraptionLoading db "InterraptionLoading", 0dh, 0ah, '$'
DATA ENDS

END Main
