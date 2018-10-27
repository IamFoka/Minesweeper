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
 
    mov ax, screen_start
	mov es, ax
	xor di, di 
	
	pop ax
	ret
endp

WRITE_SCREEN_STRING proc
	LOOP_WRITE_SCREEN_STRING:
	movsb
	mov es:di, bl
	inc di
	loop LOOP_WRITE_SCREEN_STRING 
	ret
endp






; color all characters: 
;mov cx, 12  ; number of characters. 
;mov di, 03h ; start from byte after 'h' 

;c:  mov [di], 11001110b   ; light red(1100) on yellow(1110) 
;    add di, 2 ; skip over next ascii code in vga memory. 
;    loop c

; wait for any key press: 
;mov ah, 0
;int 16h

start:

call SCREEN_MODE
call SET_DATA_SEG
call SET_SCREEN_SEG

;movsb copia de mov es:di, ds:si
;--------------------title------------------------
mov si, offset minesweeper ;
mov di, 0B2H
cld
mov bl, 04H
mov cx, 22

call WRITE_SCREEN_STRING

add di, 68H
;-----------------------------------------------------
;--------------------AUTHORS------------------------
mov si, offset authors
mov cx, 34
mov bl, 7H

call WRITE_SCREEN_STRING

add di, 0B6H
;----------------------------------------------------
;--------------------configuration------------------------

mov si, offset configuration
mov cx, 24
mov bl, 2H

call WRITE_SCREEN_STRING

add di, 016EH

;----------------------------------------------------
;--------------------configuration------------------------
mov si, offset minesamount
mov cx, 22
mov bl, 0FH

call WRITE_SCREEN_STRING
add di, 74H


mov si, offset boardwidht
mov cx, 24

call WRITE_SCREEN_STRING
add di, 70H

mov si, offset boardheight
mov cx, 23

call WRITE_SCREEN_STRING







end start
