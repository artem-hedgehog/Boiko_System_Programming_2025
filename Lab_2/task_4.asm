format ELF64 executable
entry start

segment readable executable
start:
    ; Вычисляем сумму цифр числа 5447175926
    mov rax, 5447175926
    xor r12, r12        ; Сумма цифр = 0
    mov rbx, 10         ; Делитель

sum_loop:
    xor rdx, rdx
    div rbx             ; RAX = частное, RDX = остаток (цифра)
    add r12, rdx        ; Добавляем цифру к сумме
    test rax, rax       ; Проверяем, не ноль ли частное
    jnz sum_loop        ; Если не ноль, продолжаем

    ; Преобразуем сумму в строку
    mov rax, r12
    mov rbx, 10
    lea rdi, [buffer + 20]  ; Конец буфера
    mov byte [rdi], 0       ; Нуль-терминатор

convert:
    dec rdi
    xor rdx, rdx
    div rbx
    add dl, '0'         ; Преобразуем цифру в символ
    mov [rdi], dl
    test rax, rax
    jnz convert

    ; Вычисляем длину строки
    lea rsi, [buffer + 20]
    sub rsi, rdi        ; Длина строки
    mov rdx, rsi        ; Сохраняем длину в RDX
    mov rsi, rdi        ; Указатель на начало строки

    ; Вывод результата
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    syscall

    ; Добавляем перенос строки
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall

exit:
    mov rax, 60         ; sys_exit
    xor rdi, rdi
    syscall

segment readable writeable
buffer rb 21
newline db 10