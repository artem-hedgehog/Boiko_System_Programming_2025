format elf64
public _start

include 'func.asm'


section '.data' writable
    buffer rb 1
    result_buffer rb 256
    letters_msg db "number of letters:", 0
    digits_msg db "number of digits:", 0

section '.text' executable

_start:
    pop rcx                    ; читаем количество параметров командной строки
    cmp rcx, 3                 ; должно быть 3 параметра: программа, входной файл, выходной файл
    jne error_args             ; если не 3, завершаем с ошибкой

    pop rsi                    ; argv[0] - имя программы
    pop rdi                    ; argv[1] - входной файл
    mov [input_file], rdi
    pop rdi                    ; argv[2] - выходной файл  
    mov [output_file], rdi

    ; Открываем входной файл для чтения
    mov rax, 2                 ; системный вызов открытия файла
    mov rdi, [input_file]      ; имя файла
    mov rsi, 0                 ; права только на чтение
    syscall
    cmp rax, 0                 ; проверяем успешность открытия
    jl error_open_input        ; если ошибка, завершаем
    mov [input_fd], rax        ; сохраняем файловый дескриптор

    ; Читаем файл и подсчитываем символы
    xor r8, r8                 ; счетчик букв
    xor r9, r9                 ; счетчик цифр

read_loop:
    mov rax, 0                 ; системный вызов чтения
    mov rdi, [input_fd]        ; файловый дескриптор
    mov rsi, buffer            ; буфер для чтения
    mov rdx, 1                 ; читаем по одному символу
    syscall
    
    cmp rax, 0                 ; если прочитано 0 байт - конец файла
    je read_done
    
    mov al, [buffer]           ; получаем символ
    
    ; Проверяем, является ли символ буквой (A-Z, a-z)
    cmp al, 'A'
    jb check_digit
    cmp al, 'Z'
    jbe is_letter
    
    cmp al, 'a'
    jb check_digit
    cmp al, 'z'
    jbe is_letter
    
    jmp read_loop              ; не буква и не цифра, читаем дальше

check_digit:
    ; Проверяем, является ли символ цифрой (0-9)
    cmp al, '0'
    jb read_loop
    cmp al, '9'
    ja read_loop
    inc r9                     ; нашли цифру
    jmp read_loop

is_letter:
    inc r8                     ; нашли букву
    jmp read_loop

read_done:
    ; Закрываем входной файл
    mov rax, 3                 ; системный вызов закрытия файла
    mov rdi, [input_fd]
    syscall

    ; Формируем строку результата
    mov rsi, result_buffer
    
    ; Копируем "number of letters:"
    mov rdi, letters_msg
    call copy_string
    
    ; Преобразуем количество букв в строку
    mov rax, r8
    call number_str_append
    
    ; Добавляем новую строку
    call new_line_append
    
    ; Копируем "number of digits:"
    mov rdi, digits_msg
    call copy_string
    
    ; Преобразуем количество цифр в строку
    mov rax, r9
    call number_str_append
    
    mov byte [rsi], 0          ; завершаем строку
    
    ; Вычисляем длину результата
    mov rax, result_buffer
    call len_str
    mov [result_length], rax

    ; Создаем/открываем выходной файл для записи
    mov rax, 2                 ; системный вызов открытия файла
    mov rdi, [output_file]
    mov rsi, 0x41              ; O_CREAT | O_WRONLY
    mov rdx, 0644o             ; права доступа
    syscall
    cmp rax, 0
    jl error_open_output
    mov [output_fd], rax

    ; Записываем результат в файл
    mov rax, 1                 ; системный вызов записи
    mov rdi, [output_fd]
    mov rsi, result_buffer
    mov rdx, [result_length]
    syscall

    ; Закрываем выходной файл
    mov rax, 3                 ; системный вызов закрытия файла
    mov rdi, [output_fd]
    syscall

    jmp exit

; Функция для копирования строки
; Вход: rdi - исходная строка, rsi - целевой буфер
; Выход: rsi указывает на конец скопированной строки
copy_string:
    push rax
.copy_loop:
    mov al, [rdi]
    test al, al
    jz .copy_done
    mov [rsi], al
    inc rdi
    inc rsi
    jmp .copy_loop
.copy_done:
    pop rax
    ret

; Функция для преобразования числа в строку с добавлением
; Вход: rax - число, rsi - целевой буфер
; Выход: rsi указывает на конец строки
number_str_append:
    push rax
    push rdi
    mov rdi, rsi
    call number_str
    
    ; Вычисляем длину полученной строки и перемещаем rsi
    mov rax, rdi
    call len_str
    add rsi, rax
    
    pop rdi
    pop rax
    ret

; Функция для добавления символа новой строки
; Вход: rsi - целевой буфер
; Выход: rsi указывает на следующую позицию
new_line_append:
    mov byte [rsi], 0xA
    inc rsi
    ret

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

section '.bss' writable
    input_file dq ?
    output_file dq ?
    input_fd dq ?
    output_fd dq ?
    result_length dq ?

section '.data' writable
    error_args_msg db "Usage: program input_file output_file", 0
    error_open_input_msg db "Error: Cannot open input file", 0
    error_open_output_msg db "Error: Cannot open output file", 0