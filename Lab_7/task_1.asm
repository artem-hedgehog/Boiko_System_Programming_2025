format elf64
public _start

; Системные вызовы
SYS_READ = 0
SYS_WRITE = 1
SYS_FORK = 57
SYS_EXECVE = 59
SYS_EXIT = 60
SYS_WAIT4 = 61
SYS_OPEN = 2
SYS_CLOSE = 3

STDIN = 0
STDOUT = 1

section '.data' writable
    prompt db 'Введите команду (task_1/program или exit для выхода): ', 0
    
    ; Пути к исполняемым файлам
    lab5_path db '../Lab_5/task_1', 0
    lab6_path db '../Lab_6/program', 0
    exit_cmd db 'exit', 0
    
    ; Тестовые файлы для аргументов
    input_file db 'test_input.txt', 0
    output_file db 'test_output.txt', 0
    
    ; Команды для сравнения (то, что вводит пользователь)
    cmd_task1 db 'task_1', 0
    cmd_program db 'program', 0
    
    newline db 10, 0
    error_msg db 'Ошибка: команда не найдена', 10, 0
    found_msg db 'Запускаю программу...', 10, 0
    debug_msg db 'DEBUG: Сравниваю команду: ', 0
    debug_cmd db '        Введено: ', 0
    debug_with db '        Сравниваю с: ', 0
    
    ; Аргументы для execve
    lab5_args dq lab5_path, input_file, output_file, 0
    lab6_args dq lab6_path, 0
    
    ; Переменные окружения для терминала
    term_env db 'TERM=xterm-256color', 0
    shell_env db 'SHELL=/bin/bash', 0
    path_env db 'PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin', 0
    pwd_env db 'PWD=/workspaces/Boiko_System_Programming_2025/Lab_7', 0
    
    ; Массив переменных окружения
    environment dq term_env, shell_env, path_env, pwd_env, 0

section '.bss' writable
    command_buffer rb 256
    child_pid rq 1
    status rq 1
    debug_buffer rb 256

section '.text' executable

; Функция вывода строки
; rsi - указатель на строку
print_string:
    push rdi
    push rsi
    push rdx
    push rax
    push rcx
    
    mov rdi, rsi
    call strlen
    mov rdx, rax
    
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    syscall
    
    pop rcx
    pop rax
    pop rdx
    pop rsi
    pop rdi
    ret

; Функция вычисления длины строки
strlen:
    xor rax, rax
.loop:
    cmp byte [rdi + rax], 0
    je .done
    inc rax
    jmp .loop
.done:
    ret

; Функция сравнения строк
; rdi - строка 1, rsi - строка 2
; возвращает rax: 0 - равны, 1 - не равны
strcmp:
    push rdi
    push rsi
    push rbx
    push rcx
.loop:
    mov al, byte [rdi]
    mov bl, byte [rsi]
    cmp al, bl
    jne .not_equal
    test al, al
    jz .equal
    inc rdi
    inc rsi
    jmp .loop
.equal:
    xor rax, rax
    jmp .done
.not_equal:
    mov rax, 1
.done:
    pop rcx
    pop rbx
    pop rsi
    pop rdi
    ret

; Функция отладки - выводит отладочную информацию
debug_command:
    push rdi
    push rsi
    push rax
    
    ; Выводим отладочное сообщение
    mov rsi, debug_msg
    call print_string
    
    ; Выводим введенную команду
    mov rsi, debug_cmd
    call print_string
    mov rsi, command_buffer
    call print_string
    mov rsi, newline
    call print_string
    
    ; Выводим с чем сравниваем
    mov rsi, debug_with
    call print_string
    mov rsi, rdi  ; rdi содержит команду для сравнения
    call print_string
    mov rsi, newline
    call print_string
    
    pop rax
    pop rsi
    pop rdi
    ret

; Функция чтения команды
read_command:
    push rdi
    push rsi
    push rdx
    push rcx
    
    mov rsi, prompt
    call print_string
    
    mov rax, SYS_READ
    mov rdi, STDIN
    mov rsi, command_buffer
    mov rdx, 256
    syscall
    
    cmp rax, 0
    jle .done
    
    ; Убираем символ новой строки
    mov byte [command_buffer + rax - 1], 0
    
.done:
    pop rcx
    pop rdx
    pop rsi
    pop rdi
    ret

; Функция создания тестового файла
create_test_file:
    push rdi
    push rsi
    push rdx
    push rax
    
    mov rax, SYS_OPEN
    mov rdi, input_file
    mov rsi, 0x42  ; O_CREAT | O_WRONLY | O_TRUNC
    mov rdx, 0644o
    syscall
    
    cmp rax, 0
    jl .done
    
    mov rdi, rax
    
    mov rax, SYS_WRITE
    mov rsi, test_data
    mov rdx, test_data_len
    syscall
    
    mov rax, SYS_CLOSE
    syscall
    
.done:
    pop rax
    pop rdx
    pop rsi
    pop rdi
    ret

; Функция проверки существования файла
check_file_exists:
    push rdi
    push rsi
    push rdx
    
    mov rax, SYS_OPEN
    mov rsi, 0
    mov rdx, 0
    syscall
    
    cmp rax, 0
    jl .not_exists
    
    mov rdi, rax
    mov rax, SYS_CLOSE
    syscall
    xor rax, rax
    jmp .done
    
.not_exists:
    mov rax, -1
    
.done:
    pop rdx
    pop rsi
    pop rdi
    ret

; Функция выполнения команды
execute_command:
    push rdi
    push rsi
    push rdx
    push rcx
    
    ; Отладочный вывод введенной команды
    mov rsi, debug_msg
    call print_string
    mov rsi, command_buffer
    call print_string
    mov rsi, newline
    call print_string
    
    ; Сравниваем с "exit"
    mov rdi, command_buffer
    mov rsi, exit_cmd
    call strcmp
    test rax, rax
    jz .exit
    
    ; Сравниваем с "task_1"
    mov rdi, command_buffer
    mov rsi, cmd_task1
    call strcmp
    test rax, rax
    jz .run_lab5
    
    ; Сравниваем с "program" 
    mov rdi, command_buffer
    mov rsi, cmd_program
    call strcmp
    test rax, rax
    jz .run_lab6
    
    ; Если не нашли команду, выводим отладочную информацию
    mov rsi, error_msg
    call print_string
    
    ; Выводим что было введено
    mov rsi, debug_cmd
    call print_string
    mov rsi, command_buffer
    call print_string
    mov rsi, newline
    call print_string
    
    jmp .done
    
.run_lab5:
    ; Проверяем существование файла Lab_5
    mov rdi, lab5_path
    call check_file_exists
    test rax, rax
    jnz .file_not_found
    
    call create_test_file
    
    mov rsi, found_msg
    call print_string
    
    mov rdi, lab5_path
    mov rsi, lab5_args
    mov rdx, environment
    jmp .fork_and_exec
    
.run_lab6:
    ; Проверяем существование файла Lab_6
    mov rdi, lab6_path
    call check_file_exists
    test rax, rax
    jnz .file_not_found
    
    mov rsi, found_msg
    call print_string
    
    mov rdi, lab6_path
    mov rsi, lab6_args
    mov rdx, environment
    jmp .fork_and_exec
    
.fork_and_exec:
    mov rax, SYS_FORK
    syscall
    
    test rax, rax
    jz .child_process
    jg .parent_process
    jmp .done
    
.child_process:
    mov rax, SYS_EXECVE
    syscall
    
    ; Если execve вернулся - ошибка
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall
    
.parent_process:
    mov [child_pid], rax
    
    mov rax, SYS_WAIT4
    mov rdi, [child_pid]
    mov rsi, status
    mov rdx, 0
    mov r10, 0
    syscall
    
    jmp .done
    
.file_not_found:
    mov rsi, error_msg
    call print_string
    jmp .done
    
.exit:
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall
    
.done:
    pop rcx
    pop rdx
    pop rsi
    pop rdi
    ret

_start:
    call create_test_file
    
.main_loop:
    call read_command
    
    ; Проверяем, не пустая ли команда
    mov rdi, command_buffer
    call strlen
    test rax, rax
    jz .main_loop
    
    call execute_command
    jmp .main_loop

section '.data' writable
    test_data db 'Hello World 12345 ABCdef 789 Testing Lab5 Program', 10
    test_data_len = $ - test_data