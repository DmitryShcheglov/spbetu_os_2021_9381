TESTPC SEGMENT
		ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
		ORG 100H
START: 	JMP	BEGIN



in_memory	db	'Inaccessible memory adress:     $'
adress			db	'Environment adress:     $'
tail				db	'Tail of command line:  $'
content	db	'Environment area contents:  $'
path	       		db	'Loadable path:  $'
endl 				db  13, 10, '$'

;ПРОЦЕДУРЫ
;перевод десятичной цифры в код символа
;--------------------------------------------------------------------------------
TETR_TO_HEX		PROC	near
		and		al, 0fh ;логическое умножение всех пар битов
		cmp		al, 09
		jbe		NEXT ;Переход если ниже или равно
		add		al, 07
NEXT:	add		al, 30h
		ret
TETR_TO_HEX		ENDP


;перевод байта 16 с.с в символьный код
;байт в аl переводится в 2 символа шестнадцетиричного числа в ах
;--------------------------------------------------------------------------------
BYTE_TO_HEX		PROC near
		push	cx
		mov		ah, al
		call	TETR_TO_HEX
		xchg	al, ah ;обмен местами регистра/памяти и регистра
		mov		cl, 4 
		shr		al, cl ;логический сдвиг вправо
		call	TETR_TO_HEX 
		pop		cx 			
		ret
BYTE_TO_HEX		ENDP
;--------------------------------------------------------------------------------
;Перевод в 16 сс 16-ти разрядного числа
;ax - число, di - адрес последнего символа
WRD_TO_HEX		PROC	near
		push	bx
		mov		bh, ah
		call	BYTE_TO_HEX
		mov		[di], ah
		dec		di ;вычитает 1 из операнда
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
WRD_TO_HEX		ENDP

;--------------------------------------------------------------------------------

BEGIN:
		;сегментные адреса недоступной памяти
		mov 	ax, es:[0002h]
		mov 	di, offset in_memory+31
		call 	WRD_TO_HEX
		mov 	dx, offset in_memory
		mov 	ah, 09h
		int		21h
		mov		dx, offset endl
		mov		ah, 09h
		int 	21h

		;сегментный адрес среды
		mov 	ax, es:[002Ch]
		mov 	di, offset adress+23
		call 	WRD_TO_HEX
		mov 	dx, offset adress
		mov 	ah, 09h
		int		21h
		mov		dx, offset endl
		mov		ah, 09h
		int 	21h

		;хвост командной строки в символьном виде
		mov	dx, offset tail			
		mov 	ah, 09h
		int 	21h
		xor 	cx, cx
		xor 	bx, bx
		mov 	cl, byte PTR es:[80h]
		mov 	bx, 81h 
cycle1:
		cmp		cx, 0h
		je		continue1
		mov 	dl, byte PTR es:[bx]
		mov		ah, 02h; вывод символа на экран
		int		21h
		inc		bx
		dec		cx
		jmp		cycle1
continue1:		
		mov		dx, offset endl
		mov 	ah, 09h
		int 	21h

		;содержимое области среды в символьном виде
		push	es
		mov		dx, offset content
		mov 	ah, 09h
		int 	21h
		mov		dx, offset endl
		mov 	ah, 09h
		int 	21h
		mov		bx, es:[002Ch]
		mov		es, bx
		xor 	bx, bx
		
continue2:
		mov 	dl, byte PTR es:[bx] 
		cmp 	dl, 0h
		je 	cycle2
		mov	ah, 02h
		int	21h
		inc 	bx
		jmp 	continue2
cycle2:
		mov	dx, offset endl
		mov 	ah, 09h
		int 	21h
		inc 	bx
		mov 	dl, byte PTR es:[bx] 
		cmp 	dl, 0h
		je 		quit2
		jmp 	continue2
quit2:
 
	

;Путь загружаемого модуля
		
		add 	bx, 3
		mov		dx, offset endl
		mov 	ah, 09h
		int 	21h
		mov		dx, offset path
		mov 	ah, 09h
		int 	21h
	

cycle3:
		mov 	dl, byte PTR es:[bx] 
		cmp 	dl, 0h
		je		quit3
		mov		ah, 02h
		int		21h 
		inc		bx
		jmp 	cycle3
quit3:	


		mov 	dx, offset endl
		mov 	ah, 09h
		int	21h
	
		;выход в dos
		xor		al, al
		mov 	ah, 4ch
		int		21h
		ret
TESTPC 	ENDS
		END  	START