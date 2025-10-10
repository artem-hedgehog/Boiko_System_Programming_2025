format ELF64 executable
entry start

segment readable executable

start:
    ; Вывод приглашения
    mov rax, 1
    mov rdi, 1
    mov rsi, prompt
    mov rdx, prompt_len
    syscall

    ; Чтение n
    mov rax, 0
    mov rdi, 0
    mov rsi, input_buffer
    mov rdx, 20
    syscall

    ; Преобразование строки в число
    mov rsi, input_buffer
    xor rax, rax
    xor rcx, rcx
convert_loop:
    mov cl, [rsi]
    cmp cl, 10     ; Проверка на конец строки (LF)
    je convert_done
    cmp cl, 13     ; Проверка на конец строки (CR)
    je convert_done
    cmp cl, '0'
    jb convert_done
    cmp cl, '9'
    ja convert_done
    sub cl, '0'
    imul rax, 10
    add rax, rcx
    inc rsi
    jmp convert_loop
convert_done:
    mov [n], rax

    ; Инициализация счетчика
    mov qword [count], 0
    
    ; Проверяем, что n > 0
    cmp rax, 0
    jle print_result

    ; Поиск чисел, кратных 481 (37*13)
    mov rcx, 481        ; Начинаем с первого кратного 481
find_multiples:
    cmp rcx, [n]
    jg print_result
    
    ; Увеличиваем счетчик
    inc qword [count]
    
    ; Переходим к следующему кратному
    add rcx, 481
    jmp find_multiples

print_result:
    ; Вывод результата
    mov rax, 1
    mov rdi, 1
    mov rsi, result_msg
    mov rdx, result_len
    syscall

    ; Преобразование числа в строку
    mov rax, [count]
    mov rdi, output_buffer
    call int_to_string

    ; Вывод числа
    mov rax, 1
    mov rdi, 1
    mov rsi, output_buffer
    mov rdx, 20
    syscall

    ; Вывод новой строки
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall

    ; Завершение программы
    mov rax, 60
    xor rdi, rdi
    syscall

; Простая функция преобразования числа в строку
int_to_string:
    mov rbx, 10
    mov rcx, 19
    mov byte [rdi + rcx], 0  ; Завершающий ноль
    dec rcx
    
convert_digits:
    xor rdx, rdx
    div rbx
    add dl, '0'
    mov [rdi + rcx], dl
    dec rcx
    test rax, rax
    jnz convert_digits
    
    ; Сдвигаем строку в начало буфера
    mov rsi, rdi
    add rsi, rcx
    inc rsi
    mov rdi, output_buffer
    mov rcx, 20
    rep movsb
    
    ret

segment readable writeable

prompt db 'Введите n: '
prompt_len = $ - prompt

result_msg db 'Количество чисел: '
result_len = $ - result_msg

newline db 10

n dq 0
count dq 0
input_buffer rb 20
output_buffer rb 20
    db 0  ; Дополнительный байт для безопасности