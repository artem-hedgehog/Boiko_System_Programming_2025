format ELF64

public _start

include 'func.asm'

section '.text' executable
_start:
    pop rcx            ; argc
    cmp rcx, 4
    jne error_args

    ; Получаем аргументы командной строки
    pop rsi            ; argv[0] - имя программы
    pop rsi            ; argv[1] - входной файл
    mov [input_file], rsi
    pop rsi            ; argv[2] - выходной файл
    mov [output_file], rsi
    pop rsi            ; argv[3] - значение k
    
    ; Преобразуем k в число
    call str_number
    mov [k_value], rax
    
    cmp rax, 0
    jle error_k_value

    ; Открываем входной файл для чтения
    mov rax, 2         ; sys_open
    mov rdi, [input_file]
    mov rsi, 0         ; O_RDONLY
    mov rdx, 0
    syscall
    
    cmp rax, 0
    jl error_open_input
    mov [input_fd], rax

    ; Читаем данные из файла
    mov rax, 0         ; sys_read
    mov rdi, [input_fd]
    mov rsi, buffer
    mov rdx, BUFFER_SIZE
    syscall
    
    mov [bytes_read], rax

    ; Закрываем входной файл
    mov rax, 3         ; sys_close
    mov rdi, [input_fd]
    syscall

    ; Обрабатываем данные - выбираем каждый k-й символ
    mov rcx, [bytes_read]
    mov rsi, buffer
    mov rdi, output_buffer
    mov r8, [k_value]  ; значение k
    xor r9, r9         ; счетчик позиции (начинаем с 0)
    xor r10, r10       ; счетчик выходных символов

process_loop:
    cmp rcx, 0
    je process_done
    
    ; Проверяем, является ли текущая позиция кратной k
    ; (позиция + 1) % k == 0, так как начинаем с первого символа
    mov rax, r9
    inc rax            ; позиция + 1 (т.к. начинаем с 0)
    xor rdx, rdx
    div r8
    cmp rdx, 0
    jne skip_char
    
    ; Копируем символ в выходной буфер
    mov al, [rsi]
    mov [rdi], al
    inc rdi
    inc r10

skip_char:
    inc rsi
    inc r9
    dec rcx
    jmp process_loop

process_done:
    mov [output_length], r10  ; сохраняем длину выходных данных

    ; УДАЛЯЕМ старый файл перед созданием нового
    mov rax, 87        ; sys_unlink - удаляем файл
    mov rdi, [output_file]
    syscall
    ; Игнорируем ошибку, если файла не существует

    ; Создаем/открываем выходной файл для записи
    mov rax, 2         ; sys_open
    mov rdi, [output_file]
    mov rsi, 0x41      ; O_CREAT | O_WRONLY
    mov rdx, 0644o     ; права доступа
    syscall
    
    cmp rax, 0
    jl error_open_output
    mov [output_fd], rax

    ; Записываем результат в файл
    mov rax, 1         ; sys_write
    mov rdi, [output_fd]
    mov rsi, output_buffer
    mov rdx, [output_length]
    syscall

    ; Закрываем выходной файл
    mov rax, 3         ; sys_close
    mov rdi, [output_fd]
    syscall

    jmp exit

error_args:
    mov rsi, error_args_msg
    call print_str
    call new_line
    jmp exit

error_open_input:
    mov rsi, error_open_input_msg
    call print_str
    call new_line
    jmp exit

error_open_output:
    mov rsi, error_open_output_msg
    call print_str
    call new_line
    jmp exit

error_k_value:
    mov rsi, error_k_value_msg
    call print_str
    call new_line
    jmp exit

section '.bss' writable
    input_file dq ?
    output_file dq ?
    input_fd dq ?
    output_fd dq ?
    k_value dq ?
    bytes_read dq ?
    output_length dq ?
    
    BUFFER_SIZE = 4096
    buffer rb BUFFER_SIZE
    output_buffer rb BUFFER_SIZE

section '.data' writable
    error_args_msg db "Usage: program input_file output_file k", 0
    error_open_input_msg db "Error: Cannot open input file", 0
    error_open_output_msg db "Error: Cannot open output file", 0
    error_k_value_msg db "Error: k must be positive integer", 0