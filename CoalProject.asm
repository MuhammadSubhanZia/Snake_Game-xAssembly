[org 0x100]
jmp start

; Constants
TOP:    equ 5
LEFT:   equ 10
BOTTOM: equ 20
RIGHT:  equ 70
BORDER: equ 0x0F    ; White on black
MENU_X: equ 35      ; X position for menu
MENU_Y: equ 12      ; Y position for menu
SELECTED_COLOR: equ 0x1F  ; Blue background for selected option
NORMAL_COLOR: equ 0x0F    ; White on black for normal option

current_selection: db 1   ; 1=Start, 2=Exit

start:
    ; Set video mode to 80x25 text
    mov ax, 0x0003
    int 10h

    ; Show menu
    call show_menu

    ; Menu input loop
menu_loop:
    ; Get keypress
    mov ah, 0
    int 16h

    ; Check for W or w
    cmp al, 'w'
    je .up
    cmp al, 'W'
    je .up

    ; Check for S or s
    cmp al, 's'
    je .down
    cmp al, 'S'
    je .down

    ; Check for Enter key
    cmp al, 0x0D
    je .select

    jmp menu_loop

.up:
    mov byte [current_selection], 1
    call show_menu
    jmp menu_loop
.down:
    mov byte [current_selection], 2
    call show_menu
    jmp menu_loop

.select:
    cmp byte [current_selection], 1
    je .start_selected_action

    ; Else exit
    mov ax, 0x4C00
    int 21h

.start_selected_action:
    ; Clear screen before drawing rectangle
    mov ax, 0x0600
    mov bh, 0x07
    xor cx, cx
    mov dx, 0x184F
    int 10h

    jmp draw_rectangle


; Show menu with selection highlight
show_menu:
    pusha
    ; Clear screen
    mov ax, 0x0600
    mov bh, 0x07
    xor cx, cx
    mov dx, 0x184F
    int 10h

    ; Set cursor position
    mov ah, 0x02
    xor bh, bh
    mov dx, MENU_Y<<8 | MENU_X
    int 10h

    ; Print "Start" option
    mov si, start_text
    cmp byte [current_selection], 1
    je .start_selected
    mov bl, NORMAL_COLOR
    jmp .print_start
.start_selected:
    mov bl, SELECTED_COLOR
.print_start:
    call print_string

    ; Move cursor down
    mov ah, 0x02
    inc dh
    mov dl, MENU_X
    int 10h

    ; Print "Exit" option
    mov si, exit_text
    cmp byte [current_selection], 2
    je .exit_selected
    mov bl, NORMAL_COLOR
    jmp .print_exit
.exit_selected:
    mov bl, SELECTED_COLOR
.print_exit:
    call print_string

    popa
    ret

; Print string at SI with color BL
print_string:
    pusha
    mov ah, 0x09
.print_char:
    lodsb
    cmp al, 0
    je .done
    mov bh, 0
    mov cx, 1
    int 10h
    
    ; Move cursor right
    mov ah, 0x02
    inc dl
    int 10h
    
    mov ah, 0x09
    jmp .print_char
.done:
    popa
    ret

; Draw rectangle (original functionality)
draw_rectangle:
    ; Draw top and bottom borders
    mov cx, RIGHT - LEFT + 1
    mov dl, LEFT
    mov dh, TOP
    call draw_horizontal
    mov dh, BOTTOM
    call draw_horizontal

    ; Draw left and right borders
    mov cx, BOTTOM - TOP - 1
    mov dl, LEFT
    mov dh, TOP + 1
    call draw_vertical
    mov dl, RIGHT
    call draw_vertical

    ; Draw corners
    mov dl, LEFT
    mov dh, TOP
    call draw_corner
    mov dl, RIGHT
    call draw_corner
    mov dh, BOTTOM
    call draw_corner
    mov dl, LEFT
    call draw_corner

    ; Wait for keypress
    mov ah, 0
    int 16h

    ; Exit to DOS
    mov ax, 0x4C00
    int 21h

; (Keep all your existing draw_horizontal, draw_vertical, and draw_corner functions here)
draw_horizontal:
    pusha
    mov ah, 0x02     ; Set cursor position
    mov bh, 0        ; Page 0
    int 10h

    mov ah, 0x09     ; Write character/attribute
    mov al, 0xCD     ; Horizontal line character
    mov bh, 0        ; Page 0
    mov bl, BORDER   ; Color attribute (white on black)
    int 10h
    popa
    ret

draw_vertical:
    pusha
.vloop:
    mov ah, 0x02     ; Set cursor position
    mov bh, 0        ; Page 0
    int 10h

    mov ah, 0x09     ; Write character/attribute
    mov al, 0xBA     ; Vertical line character
    mov bh, 0        ; Page 0
    mov bl, BORDER   ; Color attribute (white on black)
    push cx
    mov cx, 1        ; Write 1 character
    int 10h
    pop cx

    inc dh           ; Move down
    loop .vloop
    popa
    ret

draw_corner:
    pusha
    mov ah, 0x02     ; Set cursor position
    mov bh, 0        ; Page 0
    int 10h

    mov ah, 0x09     ; Write character/attribute
    mov al, 0xC9     ; Corner character (top-left)
    
    ; Determine appropriate corner character
    cmp dl, LEFT
    jne .not_left
    cmp dh, TOP
    jne .not_top_left
    mov al, 0xC9     ; Top-left corner
    jmp .draw
.not_top_left:
    cmp dh, BOTTOM
    jne .draw
    mov al, 0xC8     ; Bottom-left corner
    jmp .draw
.not_left:
    cmp dl, RIGHT
    jne .draw
    cmp dh, TOP
    jne .not_top_right
    mov al, 0xBB     ; Top-right corner
    jmp .draw
.not_top_right:
    mov al, 0xBC     ; Bottom-right corner

.draw:
    mov bh, 0        ; Page 0
    mov bl, BORDER   ; Color attribute (white on black)
    mov cx, 1        ; Write 1 character
    int 10h
    popa
    ret

; Data
start_text: db "Start", 0
exit_text: db "Exit", 0