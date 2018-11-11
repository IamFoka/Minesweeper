.model small

.stack 100H

.data
screen_start EQU 0B800H

minesWeeper db 'C A M P O  M I N A D O'
authors db 'GUILHERME BARRAGAM e LUCAS ALESSIO'
configuration db 'C O N F I G  U R A C A O'
minesAmount db 'NUMERO DE MINAS (>=5):'
boardWidht db 'LARGURA DO CAMPO [5;40]:'
boardHeight db 'ALTURA DO CAMPO [5;20]:'

configurationMinesAmount dw ?
configurationBoardWidht db ?
configurationBoardHeight db ?

boardRow db 40 DUP(?)



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
	xor di, di 
	
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

SHOW_MENU proc
	;movsb '==' mov es:di, ds:si
	;--------------------title------------------------
	mov si, offset minesWeeper ; set string offset
	mov di, 017AH ; set screen buffer offset
	cld ; indicates cursor direction
	mov bl, 4H ; set color (red = 4H)
	mov cx, 22 ; set string lenght

	call WRITE_SCREEN_STRING ; prints string on the screen buffer

	add di, 108H ; moves cursor to the next string position on screen (already centralized)(1 line = 50H)

	;--------------------AUTHORS------------------------
	mov si, offset authors ; set string offset
	mov cx, 34 ; set string lenght
	mov bl, 7H  ; set color (light gray = 7H)

	call WRITE_SCREEN_STRING ; prints string on the screen buffer

	add di, 1A6H ; moves cursor to the next string position on screen (already centralized)(1 line = 50H)

	;--------------------configuration------------------------

	mov si, offset configuration ; set string offset
	mov cx, 24 ; set string lenght
	mov bl, 2H  ; set color (green = 2H)

	call WRITE_SCREEN_STRING; prints string on the screen buffer

	add di, 196H ; moves cursor to the next string position on screen (already indentated)(1 line = 50H)

	;----------------------------------------------------
	;--------------------configuration------------------------
	mov si, offset minesAmount ; set string offset
	mov cx, 22 ; set string lenght
	mov bl, 0FH   ; set color (white = 0FH)

	call WRITE_SCREEN_STRING ; prints string on the screen buffer
	add di, 114H ; moves cursor to the next string position on screen (already indentated)(1 line = 50H)


	mov si, offset boardWidht ; set string offset
	mov cx, 24 ; set string lenght

	call WRITE_SCREEN_STRING ; prints string on the screen buffer
	add di, 110H ; moves cursor to the next string position on screen (already indentated)(1 line = 50H)

	mov si, offset boardHeight ; set string offset
	mov cx, 23 ; set string lenght

	call WRITE_SCREEN_STRING ; prints string on the screen buffer
	ret
endp

READ_TWO_DIGIT_DECIMAL_NUMBER proc ; read 2 digit decimal number and return it on dx
    push ax
    push bx
    
    mov ah, 1H  ; function int 21h interruption: read character from standart input
	int 21H ; 
	
	sub al, '0' ; convert the char inputed into decimal
	mov bl, 10  ; mov 10 to bl, to use on mul function
	mul bl      ; mul by 10 because is the decimal character
	mov dx, ax  ; store the actual value   
    
    mov ah, 1H ; function int 21h interruption: read character from standart input
	int 21H
	
	xor ah, ah ; clear ah to use ax(the data's on al, but we need to pass ah too) on add later
	sub al, '0'; convert the char inputed into decimal 
	add dx, ax ; add the actual value with the unit character of the complete number  
	
	pop bx
	pop ax
	ret
endp

READ_THREE_DIGIT_DECIMAL_NUMBER proc ; read 3 digit decimal number and return it on dx
    push ax
    push bx
    
	mov ah, 1H  ; function int 21h interruption: read character from standart input
	int 21H ; 
	
	sub al, '0' ;
	mov bl, 100 ;
	mul bl      ; mul by 10 because is the decimal character
	mov dx, ax  ; store the actual value   
	
    mov ah, 1H ; function int 21h interruption: read character from standart input
	int 21H ; 
	
	sub al, '0' ; convert the char inputed into decimal
	mov bl, 10  ; mov 10 to bl, to use on mul function
	mul bl      ; mul by 10 because is the decimal character
	add dx, ax ; store the actual value   
    
    mov ah, 1H ; function int 21h interruption: read character from standart input
	int 21H
	
	xor ah, ah ; clear ah to use ax(the data's on al, but we need to pass ah too) on add later
	sub al, '0'; convert the char inputed into decimal 
	add dx, ax ; add the actual value with the unit character of the complete number  
	
	pop bx
	pop ax
	ret
endp

TEST_VALUE_CONFIGURATION_5 proc ; test if the value on dx is higher then 5
    cmp dx, 5
	js start
	ret 
endp  
    

TEST_VALUE_CONFIGURATION_5_40 proc ; tests if the value (on dx) is higher then 5 and lower then 40, uses the DX rep to test the value
	push cx
	
	call TEST_VALUE_CONFIGURATION_5
	
	mov cx, 40
	cmp cx, dx
	js start
	
	pop cx
	ret
endp
	
TEST_VALUE_CONFIGURATION_5_20 proc ; tests if the value (on dx) is higher then 5 and lower then 20, uses the DX rep to test the value
	push cx
	
	call TEST_VALUE_CONFIGURATION_5
	
	mov cx, 20
	cmp cx, dx
	js start
	
	pop cx
	ret
endp

	
    

INSERT_GAME_CONFIGURATION proc
    mov ah, 2H ; function 2 on 10H interruption = set cursor position
    xor bh, bh ; page number (0 for graphics mode) from interruption 10H
	mov dh, 10 ; set the cursor row
	mov dl, 37 ; set the cursor column
	int 10H	   ; interruption to set the cursor position
	
    call READ_THREE_DIGIT_DECIMAL_NUMBER
    call TEST_VALUE_CONFIGURATION_5
	mov configurationMinesAmount, dx
	
	mov dh, 12 ; set the cursor row
	mov dl, 39 ; set the cursor column
	int 10H    ; interruption to set the cursor position
	
	call READ_TWO_DIGIT_DECIMAL_NUMBER
	call TEST_VALUE_CONFIGURATION_5_40
	xor dh, dh
	mov configurationBoardWidht, dl
	
	mov dh, 14 ; set the cursor row
	mov dl, 38 ; set the cursor column
	int 10H    ; interruption to set the cursor position
	
	call READ_TWO_DIGIT_DECIMAL_NUMBER
	call TEST_VALUE_CONFIGURATION_5_20
	xor dh, dh
	mov configurationBoardHeight, dl
	
	
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
	mov cl, configurationBoardHeight
	mov ch, configurationBoardWidht
	
	
	ret
endp


	
	

; wait for any key press: 
;mov ah, 0
;int 16h

start:

call SCREEN_MODE
call SET_DATA_SEG
call SET_SCREEN_SEG

call SHOW_MENU
call INSERT_GAME_CONFIGURATION

call SCREEN_MODE

end start
