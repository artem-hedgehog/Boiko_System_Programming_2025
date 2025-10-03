format ELF64

section '.data' writable
    error_args db "Error: need 3 arguments (a b c)", 0xA, 0
    error_conv db "Error: invalid number format", 0xA, 0
    buffer db 32 dup(0)
    newline db 0xA

section '.text' executable

_start:
    ; Получаем количество аргументов
    pop rcx
    cmp rcx, 4
    jne .error_args
    
    ; Пропускаем имя программы
    pop rsi
    
    ; Получаем три аргумента
    pop rsi  ; a
    pop rdi  ; b  
    pop rdx  ; c
    
    ; Сохраняем указатели на аргументы
    push rsi
    push rdi
    push rdx
    
    ; Преобразуем a
    pop rdx  ; c (порядок обратный из-за стека)
    pop rdi  ; b
    pop rsi  ; a
    
    ; Преобразуем a
    push rdi
    push rdx
    call str_to_number
    jc .error_conv
    mov r8, rax  ; сохраняем a
    
    ; Преобразуем b  
    pop rdx
    pop rsi
    push rdx
    call str_to_number
    jc .error_conv
    mov r9, rax  ; сохраняем b
    
    ; Преобразуем c
    pop rsi
    call str_to_number
    jc .error_conv
    mov r10, rax  ; сохраняем c
    
    ; Вычисляем (((a - b) + c) * b)
    mov rax, r8  ; a
    sub rax, r9  ; a - b
    add rax, r10 ; (a - b) + c
    imul rax, r9 ; ((a - b) + c) * b
    
    ; Выводим результат
    mov rdi, buffer
    call number_to_str
    mov rsi, buffer
    call print_str
    call print_newline
    
    ; Завершаем программу
    mov rax, 60
    xor rdi, rdi
    syscall

.error_args:
    mov rsi, error_args
    call print_str
    mov rax, 60
    mov rdi, 1
    syscall

.error_conv:
    mov rsi, error_conv
    call print_str
    mov rax, 60
    mov rdi, 1
    syscall

; Преобразование строки в число
; Вход: RSI - строка
; Выход: RAX - число, CF=1 при ошибке
str_to_number:
    xor rax, rax
    xor rcx, rcx
    
.loop:
    mov cl, [rsi]
    test cl, cl
    jz .done
    
    ; Проверяем что символ - цифра
    cmp cl, '0'
    jb .error
    cmp cl, '9'
    ja .error
    
    ; Преобразуем и добавляем
    sub cl, '0'
    imul rax, 10
    add rax, rcx
    
    inc rsi
    jmp .loop

.done:
    clc
    ret

.error:
    stc
    ret

; Преобразование числа в строку
; Вход: RAX - число, RDI - буфер
number_to_str:
    mov rbx, 10
    xor rcx, rcx
    test rax, rax
    jnz .loop
    
    ; Случай числа 0
    mov byte [rdi], '0'
    mov byte [rdi+1], 0
    ret

.loop:
    xor rdx, rdx
    div rbx
    push rdx
    inc rcx
    test rax, rax
    jnz .loop
    
    ; Извлекаем цифры в обратном порядке
    mov rsi, rdi
.pop_loop:
    pop rax
    add al, '0'
    mov [rdi], al
    inc rdi
    loop .pop_loop
    
    mov byte [rdi], 0
    ret

; Печать строки
; Вход: RSI - строка
print_str:
    push rsi
    call strlen
    mov rdx, rax  ; длина
    pop rsi       ; строка
    
    mov rax, 1    ; sys_write
    mov rdi, 1    ; stdout
    syscall
    ret

; Длина строки
; Вход: RSI - строка
; Выход: RAX - длина
strlen:
    xor rax, rax
.loop:
    cmp byte [rsi+rax], 0
    je .done
    inc rax
    jmp .loop
.done:
    ret

; Печать перевода строки
print_newline:
    mov rax, 1    ; sys_write
    mov rdi, 1    ; stdout  
    mov rsi, newline
    mov rdx, 1    ; длина
    syscall
    ret