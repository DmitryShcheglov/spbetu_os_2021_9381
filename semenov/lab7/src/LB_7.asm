.model small

OVSEG SEGMENT
OVSEG ENDS

DATA SEGMENT
str2 db 13,10,"Segment address:       $"
str3 db 13,10,"File not found: $"
psp dw ?
filename db 'ov1.ov', 0, 13, 10, '$'; запускаемый файл
param   dw seg OVSEG ; Load Segment, basically the space at buffer
        dw seg OVSEG ; Relocation Factor
DTA db 43 dup(?) ;
tempss dw ?
tempsp dw ?
entry dd ?
ovNum db 10
fmemerr db 0
OVERLAY_SEG DW ?
OVERLAY_OFFSET DW ? ;смещение оверлея
CODE_SEG DW ?
DATA ENDS

.stack 100h

CODE SEGMENT
ASSUME ds:DATA, cs:CODE
;----------------------------------
WriteString   PROC
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
WriteString   ENDP
;----------------------------------
FreeMEM PROC
	mov bx, ovseg
	mov ax, es
	sub bx, ax
	mov cl, 4
	shr bx, cl
	
	mov ah, 4Ah ; освобождение памяти
    int 21h  
	jc err
	jmp noterr
	err:
		mov fmemerr, 1
		jmp exr
	noterr:
		lea dx, DTA
		mov ah, 1ah
		int 21h ; устанавливаем DTA на буфер DS:DTA
		mov ah, 4Eh
		lea dx, filename
		mov cx, 0
		int 21h
		lea si, DTA
		mov dx, word ptr[si+1Ch]
		mov ax, word ptr[si+1Ah]
		mov bx, 10h
		div bx
		mov bx, ax
		mov ah, 48h
		int 21h
	exr:
		ret
FreeMem Endp
;----------------------------------
Main PROC
	 mov ax, @data
	 mov ds, ax
	 mov code_seg, cs
	 
	 call FreeMem
	
	 cmp fmemerr, 0
	 jne ex
	 tov:
		 cmp ovNum, 0
		 je ex
		 mov param, ax
		 mov param+2, ax
		 mov word ptr entry+2, ax
		 mov dx, offset str2
		 mov ah, 09h
		 int 21h
		 push ds
		 mov tempss, ss
		 mov tempsp, sp
		 mov ax, ds
		 mov es, ax
		 mov bx, offset DATA:param
		 mov dx, offset DATA:filename ;указываем dx на имя файла с ascii кодом 0 на конце
		 mov ax, 4b03h
		 int 21h
		 mov ss, tempss
		 mov sp, tempsp
		 pop ds
		 jc erld
		
		 push ds
		 call DWORD PTR entry
		 pop ds
		 push es
		 mov ah, 49h
		 mov ax, param
		 mov es, ax
		 int 21h
		 pop es
		 jmp noterld
	 erld:
	 	lea dx, str3
		call writestring
		lea dx, filename
		call writestring
		jmp ex
	 noterld:
		 dec ovnum
		 jmp tov
	 ex:
		 mov  ah,4ch                         
		 int  21h  
MAIN ENDP
;----------------------------------
CODE ENDS       
END main
		  
