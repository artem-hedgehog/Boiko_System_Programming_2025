format ELF64

public _start

extrn initscr
extrn endwin
extrn start_color
extrn init_pair
extrn getmaxx
extrn getmaxy
extrn stdscr
extrn move
extrn addch
extrn refresh
extrn getch
extrn noecho
extrn cbreak
extrn keypad
extrn nodelay
extrn COLOR_PAIR

extrn sin

extrn exit
extrn usleep

section '.bss' writable
    xmax        dq 1
    ymax        dq 1
    x           dq 0.0
    y           dq 0.0
    x_int       dq 0
    y_int       dq 0
    amplitude   dq 10.0    ; A = 10
    frequency   dq 0.6     ; ω = 0.6
    phase       dq 0.0
    temp        dq 0
    char_to_draw db 'O'

section '.data' writable
    COLOR_BLACK  equ 0
    COLOR_RED    equ 1
    
    ; Матем. константы
    pi          dq 3.14
    two_pi      dq 6.28
    step        dq 0.1
    delay_time  dq 50000

section '.text' executable

; Функция для вычисления A*sin(ωx)
calculate_sine:
    push rbp
    mov rbp, rsp
    
    movsd xmm0, [frequency]
    mulsd xmm0, [x]
    
    call sin
    
    mulsd xmm0, [amplitude]
    
    cvtsd2si rax, xmm0
    
    mov [y_int], rax
    
    pop rbp
    ret

_start:
    call initscr
    call start_color
    call noecho
    call cbreak

    mov rdi, [stdscr]
    mov rsi, 1
    call nodelay

    mov rdi, [stdscr]
    mov rsi, 1
    call keypad

    mov rdi, [stdscr]
    call getmaxy
    mov [ymax], rax
    mov rdi, [stdscr]
    call getmaxx
    mov [xmax], rax
    
    dec qword [xmax]
    dec qword [ymax]

    mov rax, [ymax]
    shr rax, 1
    mov [y_int], rax
    cvtsi2sd xmm0, rax
    movsd [y], xmm0

    mov rdi, 1
    mov rsi, COLOR_RED
    mov rdx, COLOR_BLACK
    call init_pair
    
    ; Установка начальной позиции x
    mov qword [x_int], 0
    movsd xmm0, [x]
    movsd [x], xmm0

main_loop:

    call getch
    cmp rax, -1
    je no_input
    
    cmp rax, 'q'
    je exit_program

    
no_input:
    mov rdi, [y_int]
    mov rsi, [x_int]
    call move
    
    mov rdi, ' '
    call addch
    
    call calculate_sine
    
    ; Адаптируем y к центру экрана
    mov rax, [ymax]
    shr rax, 1
    add rax, [y_int]
    mov [y_int], rax

    cmp rax, 0
    jge .check_ymax
    mov qword [y_int], 0
.check_ymax:
    cmp rax, [ymax]
    jle .check_x
    mov rax, [ymax]
    mov [y_int], rax
    
.check_x:

    inc qword [x_int]
    movsd xmm0, [x]
    addsd xmm0, [step]
    movsd [x], xmm0
    

    mov rax, [x_int]
    cmp rax, [xmax]
    jl .draw
    

    mov qword [x_int], 0
    movsd xmm0, [step]
    movsd [x], xmm0
    
.draw:
    mov rdi, 1
    call COLOR_PAIR
    mov [temp], rax

    mov rdi, [y_int]
    mov rsi, [x_int]
    call move
    
    mov rdi, 'O'
    or rdi, [temp]
    call addch
    
    ; Обновляем экран
    call refresh
    
    ; Задержка
    mov rdi, [delay_time]
    call usleep
    
    jmp main_loop


exit_program:
    call endwin
    mov rdi, 0
    call exit