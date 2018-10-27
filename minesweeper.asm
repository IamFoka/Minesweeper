.model small

.stack 100H

.data
screen_start EQU 0B800H

minesweeper db 'C A M P O  M I N A D O',
authors db 'GUILHERME BARRAGAM e LUCAS ALESSIO'
configuration db 'C O N F I G  U R A C A O'
minesamount db 'NUMERO DE MINAS (>=5):'
boardwidht db 'LARGURA DO CAMPO [5;40]:'
boardheight db 'ALTURA DO CAMPO [5;20]:'


.code

SCREEN_MODE proc;     
    mov ah, 0H ;set video mode   
    mov al, 1H ;40x25 16 color text
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
	mov si, offset minesweeper ; set string offset
	mov di, 0B2H ; set screen buffer offset
	cld ; indicates cursor direction
	mov bl, 4H ; set color (red = 4H)
	mov cx, 22 ; set string lenght

	call WRITE_SCREEN_STRING ; prints string on the screen buffer

	add di, 68H ; moves cursor to the next string position on screen (already centralized)(1 line = 50H)

	;--------------------AUTHORS------------------------
	mov si, offset authors ; set string offset
	mov cx, 34 ; set string lenght
	mov bl, 7H  ; set color (light gray = 7H)

	call WRITE_SCREEN_STRING ; prints string on the screen buffer

	add di, 0B6H ; moves cursor to the next string position on screen (already centralized)(1 line = 50H)

	;--------------------configuration------------------------

	mov si, offset configuration ; set string offset
	mov cx, 24 ; set string lenght
	mov bl, 2H  ; set color (green = 2H)

	call WRITE_SCREEN_STRING; prints string on the screen buffer

	add di, 0CEH ; moves cursor to the next string position on screen (already indentated)(1 line = 50H)

	;----------------------------------------------------
	;--------------------configuration------------------------
	mov si, offset minesamount ; set string offset
	mov cx, 22 ; set string lenght
	mov bl, 0FH   ; set color (white = 0FH)

	call WRITE_SCREEN_STRING ; prints string on the screen buffer
	add di, 74H ; moves cursor to the next string position on screen (already indentated)(1 line = 50H)


	mov si, offset boardwidht ; set string offset
	mov cx, 24 ; set string lenght

	call WRITE_SCREEN_STRING ; prints string on the screen buffer
	add di, 70H ; moves cursor to the next string position on screen (already indentated)(1 line = 50H)

	mov si, offset boardheight ; set string offset
	mov cx, 23 ; set string lenght

	call WRITE_SCREEN_STRING ; prints string on the screen buffer
	ret
endp

INSERT_GAME_CONFIGURATION proc
    mov ah, 2H ; function 2 on 10H interruption = set cursor position
    xor bh, bh ; page number (0 for graphics mode) from interruption 10H
	mov dh, 10
	mov dl, 37	
	int 10H
	
	mov ah, 0
	int 16h
	
	ret
endp

WRITE_CHAR proc ; write the character on DL reg
    push AX
    mov AH, 2 ; function 2 on 21H interruption: write character to standard output.
    int 21H
    pop AX
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

end start
