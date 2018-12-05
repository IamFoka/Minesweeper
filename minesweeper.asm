                     .model small
.stack 100H

.data
screen_start EQU 0B800H            ; start of the screen segment
screen_line_lenght EQU 0A0H        ; value of a line from the screen segment

minesWeeper db 'C A M P O  M I N A D O'
authors db 'GUILHERME BARRAGAM e LUCAS ALESSIO'
configuration db 'C O N F I G  U R A C A O'
minesAmount db 'NUMERO DE MINAS (>=5):'
boardWidth db 'LARGURA DO CAMPO [5;40]:'
boardHeight db 'ALTURA DO CAMPO [5;20]:'

labelClock db 'TEMPO JOGADO:'
labelFlags db 'CAMPOS MARCADOS:'

configurationMinesAmount dw ?
configurationBoardWidth dw ?
configurationBoardHeigth dw ?


boardColumns dw ? ; configurationBoardWidth used when building the board
boardLines dw ?   ; configurationBoardHeigth used when building the board
bombsAmount dw ?  ; configurationMinesHeight used when creating the mines

hours db 0
minutes db 0
seconds db 0

lastSecond db 0
markedPositions db 0

x dw ?
y dw ?

CR EQU 13

board dw 800 DUP(00H) ; board array
click dw ? ; variable used to keep the click location

max_gen_value dw ?
.code

SCREEN_MODE proc;
	mov ah, 0H ;set video mode
	mov al, 3H ;40x25 16 color text
	int 10H    ;INT 10 - Video BIOS Services
	ret
endp


SET_DATA_SEG proc
	mov     ax, @data
	mov     ds, ax
	ret
endp

SET_SCREEN_SEG proc
	push ax

	mov ax, screen_start ; uses ax as temporary variable
	mov es, ax ; moves screen start
	xor di, di ; set the position to the beggining of the page

	pop ax
	ret
endp

WRITE_SCREEN_STRING proc
	LOOP_WRITE_SCREEN_STRING:
		movsb ; movsb '==' mov es:di, ds:si
		mov es:di, bl ; add character attributes (color)
		inc di ; set cursor to the next character
		loop LOOP_WRITE_SCREEN_STRING
	ret
endp

CLEAR_GAME proc		; proc to clear the board after the end game screen
	xor di, di
	mov bx, offset board
	CLEAR_GAME_START:
		cmp di, 800
		jz CLEAR_GAME_END
		
		mov byte ptr [bx+di], 0
		inc di
		jmp CLEAR_GAME_START
	
	CLEAR_GAME_END:
	xor ax, ax
	xor bx, bx
	xor cx, cx
	xor dx, dx
	xor di, di
	xor si, si
	
	ret
endp
	
SHOW_MENU proc
	;movsb '==' mov es:di, ds:si
	;--------------------title------------------------
	mov si, offset minesWeeper ; set string offset
	mov di, 017AH ; set screen buffer offset
	cld ; indicates cursor direction
	mov bl, 4H ; set color (red = 4H)
	mov cx, 22 ; set string lenght

	call WRITE_SCREEN_STRING ; prints string on the screen buffer

	add di, 108H ; moves cursor to the next string position on screen (already centralized)(1 line = A0H)

	;--------------------authors------------------------
	mov si, offset authors ; set string offset
	mov cx, 34 ; set string lenght
	mov bl, 7H  ; set color (light gray = 7H)

	call WRITE_SCREEN_STRING ; prints string on the screen buffer

	add di, 1A6H ; moves cursor to the next string position on screen (already centralized)(1 line = A0H)

	;--------------------configuration------------------------

	mov si, offset configuration ; set string offset
	mov cx, 24 ; set string lenght
	mov bl, 2H  ; set color (green = 2H)

	call WRITE_SCREEN_STRING; prints string on the screen buffer

	add di, 196H ; moves cursor to the next string position on screen (already indentated)(1 line = A0H)

	;----------------------------------------------------
	;--------------------configuration------------------------
	mov si, offset minesAmount ; set string offset
	mov cx, 22 ; set string lenght
	mov bl, 0FH   ; set color (white = 0FH)

	call WRITE_SCREEN_STRING ; prints string on the screen buffer
	add di, 114H ; moves cursor to the next string position on screen (already indentated)(1 line = A0H)


	mov si, offset boardWidth ; set string offset
	mov cx, 24 ; set string lenght

	call WRITE_SCREEN_STRING ; prints string on the screen buffer
	add di, 110H ; moves cursor to the next string position on screen (already indentated)(1 line = A0H)

	mov si, offset boardHeight ; set string offset
	mov cx, 23 ; set string lenght

	call WRITE_SCREEN_STRING ; prints string on the screen buffer
	ret
endp


TEST_VALUE_CONFIGURATION_5 proc ; test if the value on dx is higher then 5
	cmp ax, 5
	js BRIDGE_GAME_CONFIGURATION
	ret
endp

TEST_VALUE_CONFIGURATION_3 proc ; test if the value on dx is higher then 3
	cmp ax, 3
	js BRIDGE_GAME_CONFIGURATION
	ret
endp

TEST_VALUE_CONFIGURATION_5_40 proc ; tests if the value (on dx) is higher then 5 and lower then 40, uses the DX rep to test the value
	push cx

	call TEST_VALUE_CONFIGURATION_5

	mov cx, 40
	cmp cx, ax
	js BRIDGE_GAME_CONFIGURATION

	pop cx
	ret
endp

TEST_VALUE_CONFIGURATION_5_20 proc ; tests if the value (on dx) is higher then 5 and lower then 20, uses the DX rep to test the value
	push cx

	call TEST_VALUE_CONFIGURATION_5

	mov cx, 20
	cmp cx, ax
	js BRIDGE_GAME_CONFIGURATION

	pop cx
	ret
endp

TEST_BOMB_QUANTITY proc ; tests if the bomb quantity = 1/3 fields
	mov ax, configurationBoardWidth
	mov bx, configurationBoardHeigth

	mul bx ; height * width => ax = board size
	mov max_gen_value, ax
	mov bx, configurationMinesAmount

	div bx ; board size / mines amount => ax = mines ratio
	call TEST_VALUE_CONFIGURATION_3

	ret
endp


INSERT_GAME_CONFIGURATION proc
	mov ah, 2H ; function 2 on 10H interruption = set cursor position
	xor bh, bh ; page number (0 for graphics mode) from interruption 10H
	mov dh, 10 ; set the cursor row
	mov dl, 38 ; set the cursor column
	int 10H       ; interruption to set the cursor position
	jmp NEXT_INSERT_GAME_CONFIGURATION

	BRIDGE_GAME_CONFIGURATION:
	jmp start

	NEXT_INSERT_GAME_CONFIGURATION:
	push ax

	call READ_UINT16
	call TEST_VALUE_CONFIGURATION_5
	mov configurationMinesAmount, ax
	mov bombsAmount, ax

	pop ax

	mov dh, 12 ; set the cursor row
	mov dl, 40 ; set the cursor column
	int 10H    ; interruption to set the cursor position

	push ax

	call READ_UINT16
	call TEST_VALUE_CONFIGURATION_5_40
	mov configurationBoardWidth, ax
	mov boardColumns, ax

	pop ax

	mov dh, 14 ; set the cursor row
	mov dl, 39 ; set the cursor column
	int 10H    ; interruption to set the cursor position

	push ax

	call READ_UINT16
	call TEST_VALUE_CONFIGURATION_5_20
	;xor dh, dh
	mov configurationBoardHeigth, ax
	mov boardLines, ax

	pop ax

	call TEST_BOMB_QUANTITY

	ret
endp

READ_CHAR proc ; read a character without echo and store it in AL
	mov AH, 7
	int 21H
	ret
endp



WRITE_UINT16 proc ; write the AX value on screen
	push AX
	push BX
	push CX
	push DX

	mov BX, 10
	xor CX, CX

	WRITE_UINT16_LOOP_1:
	xor DX, DX
	div BX
	push DX
	inc CX

	cmp AX, 0
	jnz WRITE_UINT16_LOOP_1

	WRITE_UINT16_LOOP_2:
	pop DX
	add DL, '0'
	call WRITE_CHAR

	loop WRITE_UINT16_LOOP_2

	pop DX
	pop CX
	pop BX
	pop AX

	ret
endp

READ_UINT16 proc  ; read a value and stores on AX
	push BX
	push CX
	push DX

	xor AX, AX
	xor CX, CX
	mov BX, 10

	READ_UINT16_SAVE:
	push AX    ; saves the accumulator

	READ_UINT16_READING:
	call READ_CHAR          ; read character

	cmp AL, CR              ; verify if the character is Enter
	jz READ_UINT16_END ; je

	cmp AL, '0'             ; verify if the character's between 0 and 9
	jb READ_UINT16_READING

	cmp AL, '9'
	ja READ_UINT16_READING

	mov DL, AL              ; write the character
	call WRITE_CHAR

	mov CL, AL              ; transform the character in int, and save it
	sub CL, '0'

	pop AX                  ; restores the accumulator

	mul BX
	add AX,CX

	jmp READ_UINT16_SAVE

	READ_UINT16_END:
	pop AX                  ; restores the accumulator

	;TESTA VALOR

	pop DX
	pop CX
	pop BX

	ret
endp


WRITE_CHAR proc ; write the character on DL reg
	push AX
	mov AH, 2 ; function 2 on 21H interruption: write character to standard output.
	int 21H
	pop AX
	ret
	endp

	SHOW_MINESWEEPER proc ; write the weeper on the screen
	xor di, di                        ; set the position on first position of the screen
	mov bl, 7H                        ; set the character color
	dec word ptr boardLines           ; dec the number of rows that will be writed
	add di, 144H                      ; set the position on the second row and column

	SHOW_MINESWEEPER_START:
	cmp boardColumns, 0               ; test if already write all the columns on that row
	jz SHOW_MINESWEEPER_LINE_END

	mov ah, 4
	mov es:di, ah                     ; moves the character to the screen

	inc di
	mov es:di, bl                     ; moves the character color to the screen
	inc di
	dec word ptr boardColumns         ; dec the number of columns that will be writed
	jmp SHOW_MINESWEEPER_START

	SHOW_MINESWEEPER_LINE_END:
	cmp boardLines, 0                 ; test if already write all the rows
	jz SHOW_MINESWEEPER_END

	push dx                           ; reset the number of columns to be writed
	mov dx, configurationBoardWidth   ;
	mov boardColumns, dx              ;
	pop dx                            ;

	add di, 0A0H                      ; set the position to the start of the next row
	sub di, boardColumns              ;
	sub di, boardColumns              ;

	dec word ptr boardLines           ; dec the number of rows that will be writed

	jmp SHOW_MINESWEEPER_START


	SHOW_MINESWEEPER_END:

	ret
endp

ADD_FIELD_NUMBERS proc
    push di
    push ax
    push cx
    push dx
    
    add di, 2                               ; moves right
    ;TEST IF IS NOT OUT OF RANGE HERE
    cmp byte ptr[bx+di], 0BH                ; tests if isn't a bomb
    jz ADD_FIELD_NUMBERS_NEXT1              ; if is a bomb go to next position
    inc byte ptr[bx+di]                     ; add 1 if isn't a bomb
    
    ADD_FIELD_NUMBERS_NEXT1:
		sub di, 4                               ; moves left
		;TEST IF IS NOT OUT OF RANGE HERE
		cmp byte ptr[bx+di], 0BH                ; tests if isn't a bomb
		jz ADD_FIELD_NUMBERS_NEXT2              ; if is a bomb go to next position
		inc byte ptr[bx+di]                     ; add 1 if isn't a bomb
    
    
    ADD_FIELD_NUMBERS_NEXT2:
		add di, configurationBoardWidth
		add di, configurationBoardWidth         ; moves down(on left)
		;TEST IF IS NOT OUT OF RANGE HERE
		cmp byte ptr[bx+di], 0BH                ; tests if isn't a bomb
		jz ADD_FIELD_NUMBERS_NEXT3              ; if is a bomb go to next position
		inc byte ptr[bx+di]                     ; add 1 if isn't a bomb 
		
    
    ADD_FIELD_NUMBERS_NEXT3:         
		add di, 2                               ; moves right       
		;TEST IF IS NOT OUT OF RANGE HERE
		cmp byte ptr[bx+di], 0BH                ; tests if isn't a bomb
		jz ADD_FIELD_NUMBERS_NEXT4              ; if is a bomb go to next position
		inc byte ptr[bx+di]                     ; add 1 if isn't a bomb
		
		
    ADD_FIELD_NUMBERS_NEXT4:
		add di, 2                               ; moves right
		;TEST IF IS NOT OUT OF RANGE HERE    
		cmp byte ptr[bx+di], 0BH                ; tests if isn't a bomb
		jz ADD_FIELD_NUMBERS_NEXT5              ; if is a bomb go to next position
		inc byte ptr[bx+di]                     ; add 1 if isn't a bomb
		
    
    ADD_FIELD_NUMBERS_NEXT5:
		sub di, configurationBoardWidth
		sub di, configurationBoardWidth
		sub di, configurationBoardWidth
		sub di, configurationBoardWidth         ; moves up (on right)
		;TEST IF IS NOT OUT OF RANGE HERE
		cmp byte ptr[bx+di], 0BH                ; tests if isn't a bomb
		jz ADD_FIELD_NUMBERS_NEXT6              ; if is a bomb go to next position
		inc byte ptr[bx+di]                     ; add 1 if isn't a bomb
		
    
    ADD_FIELD_NUMBERS_NEXT6:                
		sub di, 2                               ; moves left
		;TEST IF IS NOT OUT OF RANGE HERE
		cmp byte ptr[bx+di], 0BH                ; tests if isn't a bomb
		jz ADD_FIELD_NUMBERS_NEXT7              ; if is a bomb go to next position
		inc byte ptr[bx+di]                     ; add 1 if isn't a bomb
		
    
    ADD_FIELD_NUMBERS_NEXT7:
		sub di, 2                               ; moves left
		;TEST IF IS NOT OUT OF RANGE HERE
		cmp byte ptr[bx+di], 0BH                ; tests if isn't a bomb
		jz ADD_FIELD_NUMBERS_END                ; if is a bomb go to next position
		inc byte ptr[bx+di]                     ; add 1 if isn't a bomb
    
    ADD_FIELD_NUMBERS_END:
    
    pop dx
    pop cx
    pop ax
    pop di
    ret
endp

MOV_TO_BOARD proc               ; function that moves the bombs to the board
	push bx
	push ax

	mov bx, offset board        ;
	mov si, ax                     ;
	mov ax, 2                     ; multiplies the position by 2 'cause it's a word vector
	mul si                      ;
	mov si, ax
	xor ah, ah                  ;

	mov al, [bx+si]

	cmp al, 0BH                    ; verify is the position already have a bomb
	je MOV_TO_BOARD_FAIL        ;
	;
	mov ax, si                    ;
	;call WRITE_UINT16             ;
	push dx
	xor dx, dx
	mov DL, ' '
	;call WRITE_CHAR
	pop dx

	;
	mov di, si
	inc di
	mov byte ptr[bx+di], 0BH    ; if not, moves the bomb to the position
	;call ADD_FIELD_NUMBERS

	jmp MOV_TO_BOARD_END

	MOV_TO_BOARD_FAIL:          ; if yes:

		inc bombsAmount              ; increment bombsAmount 'cause the other position isn't validpois a antiga posicao gerada nao eh valida

		pop ax                        ; pop the invalid seed

		push dx
		push cx
		; gen a new seed
		xor ax, ax
		int 1AH                     ; CX:DX = number of clock ticks since midnight
		mov ax, dx                     ; initial seed in ax

		pop cx
		pop dx

		jmp MOV_TO_BOARD_END_RET

	MOV_TO_BOARD_END:

		pop ax

	MOV_TO_BOARD_END_RET:

		pop bx
	ret
endp

proc RAND
	NEW_RAND:
		push dx
		mul dx
		add ax, cx
		pop dx

		push dx
		div bx            ; divides ax by the module and use the rest to gen the new seed
		mov ax, dx

		call MOV_TO_BOARD

		pop dx
		dec bombsAmount

		cmp bombsAmount, 0
		jne NEW_RAND
	ret
endp

RANDOM_MINES proc
	push ax
	push bx
	push cx
	push dx

	xor ax, ax
	int 1AH                 ; CX:DX = number of clock ticks since midnight
	mov ax, dx                 ; initial seed in ax

	push ax

	xor dx, dx                ;
	mov ax, max_gen_value    ;
	mov bx, 2                ;
	div bx                    ; div max_gen_value by 2 and mov to dx

	mov dx, ax                ; dx is the multiplier
	mov cx, ax                ; set the same value of dx to cx and dec
	dec cx                    ; cx is the increment
	pop ax

	mov bx, max_gen_value    ; set the max value of generator

	call RAND

	pop dx
	pop cx
	pop bx
	pop ax
	ret
endp

CALCULATE_SCREEN_POSITION proc
	push ax
	push bx

	mov ax, screen_line_lenght
	mul y
	add ax, x
	mov bx, 4
	mul bx
	mov di, ax

	pop bx
	pop ax
	ret
endp

SET_CURSOR MACRO x, y
	push ax
	push bx
	push dx

	mov ah, 2H     ;  2 on 10H interruption = set cursor position
	mov dx, x ; set the cursor column
	mov bx, y
	mov dh, bl ; set the cursor row
	xor bh, bh ; page number (0 for graphics mode) from interruption 10H
	add dl, 2
	add dh, 2
	int 10H       ; interruption to set the cursor position

	pop dx
	pop bx
	pop ax
endm

MOUSE_ACTION_LEFT proc
	push ax
	push bx
	push cx
	push dx
	
	jmp CONTINUE_MOUSE_ACTION_LEFT_BRIDGE_0
	BRIDGE_MOUSE_ACTION_LEFT_0:
		jmp BRIDGE_MOUSE_ACTION_LEFT_1
	CONTINUE_MOUSE_ACTION_LEFT_BRIDGE_0:		
	
	mov ax, y
	mov dx, configurationBoardHeigth

	cmp dx, ax
	js MOUSE_ACTION_LEFT_END

	mov bx, x
	mov cx, configurationBoardWidth

	cmp cx, bx
	js MOUSE_ACTION_LEFT_END

	; ax = y
	; bx = x
	; cx = configurationBoardWidth
	; dx = configurationBoardHeigth

	mul cx                        ; mul the row by the lenght of the board
	add ax, bx                    ; add the result from the mul above with the column number

	mov cx, 2                    ;
	mul cx                        ; mul the result above by 2, 'cause it's a word vector

	mov click, ax                ; stores the final result on 'click' (this position access the status part of the field)

	mov bx, offset board
	mov di, click

	cmp byte ptr[bx+di], 1      ; cmp the status field with 1 (if 0, then the field's closed, if 1, then the field's flagged and if 2,
	; the field's already open)

	js MOUSE_ACTION_LEFT_TREATMENT    ; if zero, the field is closed, needed to check if is a bomb

	jz MOUSE_ACTION_LEFT_REMOVE_FLAG ; if one means that the field is with a flag, and need to be unmarked

	jmp MOUSE_ACTION_LEFT_END        ;if two, the field is already open

	MOUSE_ACTION_LEFT_REMOVE_FLAG:   ; == 1
		SET_CURSOR x, y
		mov byte ptr [bx+di], 0               ; if it was marked, now it's with 0, what means that he's a closed field, without flag
		xor dx, dx
		mov dl, 4
		call WRITE_CHAR
		jmp MOUSE_ACTION_LEFT_END

	MOUSE_ACTION_LEFT_TREATMENT:     ; == 0
		inc di
		cmp byte ptr [bx+di], 0BH
		jz BRIDGE_MOUSE_ACTION_LEFT_0

		SET_CURSOR x, y
		xor ax, ax
		mov al, [bx+di]
		call WRITE_UINT16

		dec di
		mov byte ptr [bx+di], 2

	MOUSE_ACTION_LEFT_END:           ; == 2

	pop dx
	pop cx
	pop bx
	pop ax
	ret
endp

MOUSE_ACTION_RIGHT proc
	push ax
	push bx
	push cx
	push dx

	mov ax, y
	mov dx, configurationBoardHeigth       ; test if the click is on the board

	cmp dx, ax
	js MOUSE_ACTION_RIGHT_END

	mov bx, x
	mov cx, configurationBoardWidth

	cmp cx, bx
	js MOUSE_ACTION_RIGHT_END

	; ax = y
	; bx = x
	; cx = configurationBoardWidth
	; dx = configurationBoardHeigth

	mul cx                        ; mul the row by the lenght of the board
	add ax, bx                    ; add the result from the mul above with the column number

	mov cx, 2                     ;
	mul cx                        ; mul the result above by 2, 'cause it's a word vector

	mov click, ax                 ; stores the final result on 'click' (this position access the status part of the field)

	mov bx, offset board
	mov di, click

	cmp byte ptr[bx+di], 0        ; cmp the status field with 0 (if 0, then the field's closed, if 1, then the field's flagged and if 2,
								  ; the field's already open)

	jz MOUSE_ACTION_RIGHT_TREATMENT   ; if zero, the field is closed, needed to check if is a bomb

	jmp MOUSE_ACTION_RIGHT_END

	MOUSE_ACTION_RIGHT_TREATMENT:   ; == 0

		mov byte ptr [bx+di], 1               ; if it was marked, now it's with 0, what means that he's a closed field, without flag

		SET_CURSOR x, y
		xor dx, dx
		mov dl, 178
		call WRITE_CHAR


	MOUSE_ACTION_RIGHT_END:           ; == 2

	pop dx
	pop cx
	pop bx
	pop ax
	ret
endp


FIX_AND_SAVE_MOUSE_COORDINATES proc
	push ax
	push bx
	push dx

	xor dx, dx  ; clear dx to don't div overflow

	mov bx, 8   ; set divisor

	mov ax, cx  ; moves cx to be divided on ax
	div bx      ; divides ax by bx
	xor ah, ah  ; clear ah where the remainder is (just need the result)
	mov cx, ax  ; moves result back to cx

	pop dx      ; get the coordenate back

	mov ax, dx  ; moves dx to be divided on ax
	xor dx, dx  ; clear dx to don't div overflow
	div bx      ; divides ax by bx
	xor ah, ah  ; clear ah where the remainder is (just need the result)
	mov dx, ax  ; moves result back to dx

	sub cx, 2
	sub dx, 2

	mov x, cx   ;stores both coordenates
	mov y, dx   ;


	pop bx
	pop ax
	ret
endp

GET_MOUSE_CLICK proc
	push ax
	push bx
	push cx
	push dx

	GET_MOUSE_CLICK_START:

	xor bl, bl                        ; clear the bl cause the result about mouse state is storaged here
	
	mov  ax, 0001h  				  ; show mouse
	int  33h
	
	mov ax, 3H                        ; Get mouse position and mouse button status
	int 33H                           ; Mouse functions


	cmp bl, 1                         ; bl = 0001 = left click
	jz GET_MOUSE_CLICK_LEFT

	cmp bl, 2                         ; bl = 0010 = right click
	jz GET_MOUSE_CLICK_RIGHT

	jmp GET_MOUSE_CLICK_END


	GET_MOUSE_CLICK_LEFT:
		call FIX_AND_SAVE_MOUSE_COORDINATES    ; get mouse coordenates
		call MOUSE_ACTION_LEFT

		jmp GET_MOUSE_CLICK_LEFT_NEXT_BRIDGE_1
		BRIDGE_MOUSE_ACTION_LEFT_1:
		jmp BRIDGE_MOUSE_ACTION_LEFT_2
		GET_MOUSE_CLICK_LEFT_NEXT_BRIDGE_1:

		jmp GET_MOUSE_CLICK_END

	GET_MOUSE_CLICK_RIGHT:
		call FIX_AND_SAVE_MOUSE_COORDINATES ; get mouse coordenates
		call MOUSE_ACTION_RIGHT

		jmp GET_MOUSE_CLICK_LEFT_NEXT_BRIDGE_2
		BRIDGE_MOUSE_ACTION_LEFT_2:
		jmp END_GAME
		GET_MOUSE_CLICK_LEFT_NEXT_BRIDGE_2:

	GET_MOUSE_CLICK_END:

	pop dx
	pop cx
	pop bx
	pop ax
	ret
endp

POSITION_TO_XY proc               ; proc que retorna x e y (bx, ax) da posicao de um elemento no vetor
	push bx
	
	xor dx, dx
	mov bx, 2
	div bx	
	mov bx, configurationBoardWidth
	div bx
	
	pop bx
	ret
endp

OPEN_FIELDS proc
	;dx = x, ax = y
	push di	
		
	mov bx, offset board	
	cmp word ptr[bx+di], 0       ; Verifica se a posicao nao esta zerada
	jne OPEN_FIELDS_END	
	mov word ptr[bx+di], 01h
	
	; ---------------------------
	
	mov ax, di
	call POSITION_TO_XY
			
	cmp ax, 0                       ; Verifica se esta na primeira linha
	je OPEN_FIELDS_C1
	sub di, configurationBoardWidth
	sub di, configurationBoardWidth
	call OPEN_FIELDS
	
	
	OPEN_FIELDS_C1:
		mov ax, di
		call POSITION_TO_XY		
		inc ax
		
		cmp ax, configurationBoardHeigth ; Verifica se esta na ultima linha
		je OPEN_FIELDS_C2                  
		add di, configurationBoardWidth
		add di, configurationBoardWidth
		call OPEN_FIELDS
	
	OPEN_FIELDS_C2:
		dec ax
					
		mov ax, di
		call POSITION_TO_XY	
		
		cmp dx, 0                         ; Verifica se esta na primeira coluna
		je OPEN_FIELDS_C3
		sub di, 2
		call OPEN_FIELDS
	
	OPEN_FIELDS_C3:
	
		mov ax, di
		call POSITION_TO_XY
		
		inc dx
		cmp dx, configurationBoardWidth   ; Verifica se esta na ultima coluna
		je OPEN_FIELDS_C4
		add di, 2
		call OPEN_FIELDS
	
	OPEN_FIELDS_C4:
		dec di
	
	;mov ax, di
	;call POSITION_TO_XY
	;cmp dx, 0
	;je OPEN_FIELDS_C5
	;cmp ax, 0
	;je OPEN_FIELDS_C5
	;sub di, configurationBoardWidth
	;sub di, configurationBoardWidth
	;sub di, 2
	;call OPEN_FIELDS
	
	;OPEN_FIELDS_C5
	
	
	
	OPEN_FIELDS_END:
	
	pop di
	
	mov ax, di
	call POSITION_TO_XY		
	SET_CURSOR dx, ax
	push dx
	xor dx, dx
	mov dl, '-'
	call WRITE_CHAR
	pop dx
		
	
	;mov ax, di
	;call POSITION_TO_XY	
	
	ret
endp

INIT_CLOCK proc
	mov si, offset labelClock ; set string offset
	mov di, 1A4H ; set screen buffer offset
	cld ; indicates cursor direction
	mov bl, 4H ; set color (red = 4H)
	mov cx, 13 ; set string lenght
	
	call WRITE_SCREEN_STRING
	
	mov ah, 2CH             ; get time
	int 21h
	mov lastSecond, dh
	
	ret	
endp

CLOCK proc
	push ax
	push dx
	
	mov ah, 2CH             ; get time
	int 21h
	
	cmp dh, lastSecond
	je CLOCK_END
	
	mov lastSecond, dh
	
	inc byte ptr seconds
	
	cmp seconds, 3CH                 ; verifica se chegou nos 60 segundos
	jne CLOCK_VERIFY_MINUTES
	
	mov seconds, 0
	inc byte ptr minutes                      ; incrementa os minutos qdo chegou nos 60 segundos
	
	CLOCK_VERIFY_MINUTES:
	
		cmp minutes, 3CH                 ; verifica se chegou nos 60 minutos 
		jne CLOCK_VERIFY_HOUR
		
		mov minutes, 0
		inc byte ptr hours                        ; incrementa as horas qdo chegou nos 60 minutos
	
	CLOCK_VERIFY_HOUR:
	
		cmp hours, 18H                   ; verifica se antigiu 24 horas e zera as horas caso haja atingido
		jne CLOCK_END
		
		mov hours, 0	

	CLOCK_END:
	
		SET_CURSOR 62, 0
		xor ax, ax
		
		mov al, hours                    ; escreve as horas na tela
		cmp hours, 9
		ja CLOCK_CONTINUE
		mov dl, '0'
		call WRITE_CHAR
		
	CLOCK_CONTINUE:		
		call WRITE_UINT16
		
		mov dl, ':'
		call WRITE_CHAR
		
		mov al, minutes                  ; escreve os minutos
		cmp minutes, 9
		ja CLOCK_CONTINUE2
		mov dl, '0'
		call WRITE_CHAR
		
	CLOCK_CONTINUE2:		
		call WRITE_UINT16
		
		mov dl, ':'
		call WRITE_CHAR
		
		mov al, seconds                 ; escreve os segundos
		cmp seconds, 9
		ja CLOCK_CONTINUE3
		mov dl, '0'
		call WRITE_CHAR

	CLOCK_CONTINUE3:	
		call WRITE_UINT16
	 
	pop dx 
	pop ax
	ret
endp

INIT_FLAGS proc
	push si
	push di
	push bx
	push cx
	push ax
	
	mov si, offset labelFlags ; set string offset
	mov di, 2E4H ; set screen buffer offset
	cld ; indicates cursor direction
	mov bl, 4H ; set color (red = 4H)
	mov cx, 16 ; set string lenght
	
	call WRITE_SCREEN_STRING
	
	mov ax, 0	
	SET_CURSOR 65, 2
	call WRITE_UINT16
	
	pop ax
	pop bx
	pop cx
	pop di
	pop si
	
	ret	
endp


MARK_POSITION proc
	push ax
	push bx
	push dx
	
	mov ax, click
	mov si, ax
	
	mov bx, offset board
	
	mov ax, word ptr[bx+si]
	
	cmp ah, 0                             ; verifica se a nao parte alta esta marcada
	jne MARK_POSITION_CONTINUE
	mov ah, 2h                            
	mov dx, si
	mov di, dx	
	mov word ptr [bx+di], ax              ; indica que a parte alta esta marcada
	
	mov ax, di
	
	call POSITION_TO_XY
	SET_CURSOR dx, ax
	
	mov dl, 176
	call WRITE_CHAR                       ; escreve o caractere da marcacao do campo
	inc byte ptr markedPositions
	
	
	MARK_POSITION_CONTINUE:
	
		cmp ah, 2h                            ; verifica se ja esta marcado
		jne MARK_POSITION_END
		mov ah, 0h
		mov dx, si
		mov di, dx	
		mov word ptr [bx+di], ax              ; remove a marcacao do campo
		
		mov ax, di
		
		call POSITION_TO_XY                   ; escreve o caractere normal do campo
		SET_CURSOR dx, ax
		
		mov dl, 4
		call WRITE_CHAR
		
		dec byte ptr markedPositions
	
	MARK_POSITION_END:
	
		xor ax, ax
		mov al, byte ptr markedPositions
		
		SET_CURSOR 65, 2
		call WRITE_UINT16
		
		mov dl, ' '
		call WRITE_CHAR
		call WRITE_CHAR
	
	pop dx	
	pop bx
	pop ax
	ret
endp

start:

call SCREEN_MODE
call SET_DATA_SEG
call SET_SCREEN_SEG
call SHOW_MENU
call INSERT_GAME_CONFIGURATION

call SCREEN_MODE
call SHOW_MINESWEEPER
call RANDOM_MINES

call INIT_CLOCK
call INIT_FLAGS


GAME:
call GET_MOUSE_CLICK

call CLOCK

jmp GAME


END_GAME:
call CLEAR_GAME
jmp start

end start