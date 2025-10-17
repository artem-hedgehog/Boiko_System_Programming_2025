format ELF64 executable 3

segment readable executable
entry start

start:
    ; Проверяем количество аргументов
    mov rcx, [rsp]          ; argc
    cmp rcx, 2
    jne error_args

    ; Получаем аргумент
    mov rsi, [rsp + 16]     ; argv[1]
    call parse_int
    test rax, rax
    js error_input

    ; Проверяем четность (2n+1 должно быть нечетным)
    test rax, 1
    jz error_even

    ; Вычисляем n = (x - 1) / 2
    dec rax
    shr rax, 1              ; n = (2n+1 - 1) / 2
    mov rbx, rax            ; сохраняем n

    ; Вычисляем сумму: 1 + 3 + 5 + ... + (2n+1) = (n+1)^2
    inc rax
    imul rax, rax
    mov rbx, rax            ; сохраняем результат

    ; Выводим результат
    mov rdi, rbx
    call print_int
    call newline
    jmp exit

error_args:
    mov rsi, error_args_msg
    mov rdx, error_args_len
    jmp print_error

error_input:
    mov rsi, error_input_msg
    mov rdx, error_input_len
    jmp print_error

error_even:
    mov rsi, error_even_msg
    mov rdx, error_even_len
    jmp print_error

print_error:
    mov rax, 1              ; sys_write
    mov rdi, 2              ; stderr
    syscall
    mov rax, 60             ; sys_exit
    mov rdi, 1              ; код ошибки
    syscall

exit:
    mov rax, 60             ; sys_exit
    xor rdi, rdi            ; код 0
    syscall

; Функция парсинга целого числа
parse_int:
    xor rax, rax
    xor rcx, rcx
.next_char:
    mov cl, [rsi]
    test cl, cl
    jz .done
    cmp cl, '0'
    jb .error
    cmp cl, '9'
    ja .error
    sub cl, '0'
    imul rax, 10
    add rax, rcx
    inc rsi
    jmp .next_char
.error:
    mov rax, -1
.done:
    ret

; Функция вывода целого числа
print_int:
    mov rax, rdi
    mov rbx, 10
    mov rcx, buffer + 20
    mov byte [rcx], 0
    dec rcx
.convert:
    xor rdx, rdx
    div rbx
    add dl, '0'
    mov [rcx], dl
    dec rcx
    test rax, rax
    jnz .convert
    inc rcx
    mov rsi, rcx
    call strlen
    mov rdx, rax
    mov rax, 1
    mov rdi, 1
    syscall
    ret

strlen:
    mov rdx, rsi
.loop:
    cmp byte [rdx], 0
    je .done
    inc rdx
    jmp .loop
.done:
    sub rdx, rsi
    mov rax, rdx
    ret

newline:
    mov rax, 1
    mov rdi, 1
    mov rsi, nl
    mov rdx, 1
    syscall
    ret

segment readable writeable
error_args_msg db "Ошибка: нужно ввести один аргумент", 10
error_args_len = $ - error_args_msg
error_input_msg db "Ошибка ввода", 10
error_input_len = $ - error_input_msg
error_even_msg db "Ошибка: введённое число должно быть нечётным (2n+1)", 10
error_even_len = $ - error_even_msg
nl db 10
buffer rb 21