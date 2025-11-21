format ELF64

public _start

; Импорт функций из библиотеки ncurses
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

; Импорт стандартных функций
extrn exit
extrn usleep

section '.bss' writable
    xmax        dq 1
    ymax        dq 1
    x           dq 0
    y           dq 0
    direction   dq 1     ; 1 = вниз, -1 = вверх
    current_color dq 1   ; 1 = красный, 2 = черный
    delay_time  dq 100000 ; начальная задержка в микросекундах
    temp        dq 0

section '.data' writable
    ; Цветовые константы ncurses
    COLOR_BLACK  equ 0
    COLOR_RED    equ 1
    COLOR_GREEN  equ 2
    COLOR_YELLOW equ 3
    COLOR_BLUE   equ 4
    COLOR_MAGENTA equ 5
    COLOR_CYAN   equ 6
    COLOR_WHITE  equ 7

section '.text' executable

_start:
    ; Инициализация ncurses
    call initscr
    call start_color
    call noecho
    call cbreak
    
    ; Включение неблокирующего режима
    mov rdi, [stdscr]
    mov rsi, 1
    call nodelay
    
    ; Включение обработки функциональных клавиш
    mov rdi, [stdscr]
    mov rsi, 1
    call keypad
    
    ; Получение размеров экрана
    mov rdi, [stdscr]
    call getmaxx
    mov [xmax], rax
    call getmaxy
    mov [ymax], rax
    
    ; Корректировка размеров (индексы начинаются с 0)
    dec qword [xmax]
    dec qword [ymax]
    
    ; Инициализация цветовых пар
    ; Пара 1: красный на черном
    mov rdi, 1
    mov rsi, COLOR_RED
    mov rdx, COLOR_BLACK
    call init_pair
    
    ; Пара 2: черный на красном  
    mov rdi, 2
    mov rsi, COLOR_BLACK
    mov rdx, COLOR_RED
    call init_pair
    
    ; Начальные координаты
    mov qword [x], 0
    mov qword [y], 0
    mov qword [direction], 1
    mov qword [current_color], 1
    
main_loop:
    ; Проверка ввода
    call getch
    cmp rax, -1
    je no_input
    
    ; Обработка клавиш
    cmp rax, 's'
    je exit_program
    cmp rax, 'S'
    je exit_program
    cmp rax, 'y'
    je increase_speed
    cmp rax, 'Y'
    je increase_speed
    
no_input:
    ; Устанавливаем цвет
    mov rdi, [current_color]
    call COLOR_PAIR
    mov [temp], rax
    
    ; Рисование текущей позиции
    mov rdi, [y]
    mov rsi, [x]
    call move
    
    ; Выводим символ с цветом
    mov rdi, ' '
    or rdi, [temp]
    call addch
    
    call refresh
    
    ; Задержка
    mov rdi, [delay_time]
    call usleep
    
    ; Перемещение курсора
    call move_cursor
    
    jmp main_loop

move_cursor:
    ; Двигаемся по вертикали
    mov rax, [direction]
    add [y], rax
    
    ; Проверка границ
    mov rax, [y]
    mov rbx, [direction]
    
    cmp rbx, 1
    jne moving_up
    
moving_down:
    cmp rax, [ymax]
    jle move_done
    ; Достигли низа - двигаемся вправо и меняем направление
    inc qword [x]
    mov qword [direction], -1
    mov rax, [ymax]
    mov [y], rax
    jmp check_right_bound
    
moving_up:
    cmp rax, 0
    jge move_done
    ; Достигли верха - двигаемся вправо и меняем направление
    inc qword [x]
    mov qword [direction], 1
    mov qword [y], 0
    
check_right_bound:
    ; Проверка правой границы
    mov rax, [x]
    cmp rax, [xmax]
    jle move_done
    
    ; Достигли правой границы - начинаем заново
    mov qword [x], 0
    mov qword [y], 0
    mov qword [direction], 1
    
    ; Меняем цвет
    mov rax, [current_color]
    cmp rax, 1
    jne set_red
    mov qword [current_color], 2
    jmp move_done
set_red:
    mov qword [current_color], 1

move_done:
    ret

increase_speed:
    ; Увеличение скорости
    mov rax, [delay_time]
    cmp rax, 20000
    jle speed_done
    sub rax, 20000
    mov [delay_time], rax
speed_done:
    jmp no_input

exit_program:
    call endwin
    mov rdi, 0
    call exit