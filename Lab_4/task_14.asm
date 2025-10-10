format ELF64 executable 3

segment readable executable
entry start

start:
    ; Чтение числа n
    mov rax, 0
    mov rdi, 0
    lea rsi, [buffer]
    mov rdx, 20
    syscall

    ; Преобразование строки в число (n)
    xor r12, r12        ; r12 = n
    lea rsi, [buffer]
convert_input:
    movzx rax, byte [rsi]
    cmp al, 10          ; Проверка на перенос строки
    je input_done
    sub al, '0'
    imul r12, r12, 10
    add r12, rax
    inc rsi
    jmp convert_input

input_done:
    mov r13, 1          ; r13 = x (текущее число)

check_loop:
    cmp r13, r12
    jg exit

    ; Вычисление x^2
    mov rax, r13
    mul rax
    mov r14, rax        ; r14 = x^2

    ; Вычисление 10^k, где k - количество цифр в x
    mov rdi, r13
    call count_digits
    mov r15, 10
    call power          ; r15 = 10^k

    ; Проверка: x^2 mod 10^k == x
    mov rax, r14
    xor rdx, rdx
    div r15             ; rdx = x^2 mod 10^k
    cmp rdx, r13
    jne next

    ; Вывод числа x
    mov rax, r13
    call print_number

next:
    inc r13
    jmp check_loop

; Функция вычисления количества цифр (результат в rcx)
count_digits:
    mov rcx, 0
    mov rax, rdi
count_loop:
    inc rcx
    mov rbx, 10
    xor rdx, rdx
    div rbx
    test rax, rax
    jnz count_loop
    ret

; Функция возведения 10 в степень rcx (результат в r15)
power:
    mov rax, 1
power_loop:
    test rcx, rcx
    jz power_done
    mul r15
    dec rcx
    jmp power_loop
power_done:
    mov r15, rax
    ret

; Функция вывода числа из rax
print_number:
    lea rsi, [output_buf + 19]
    mov byte [rsi], 10   ; Добавляем перенос строки
    mov rbx, 10
print_loop:
    dec rsi
    xor rdx, rdx
    div rbx
    add dl, '0'
    mov [rsi], dl
    test rax, rax
    jnz print_loop

    ; Системный вызов write
    mov rax, 1
    mov rdi, 1
    mov rdx, output_buf + 20
    sub rdx, rsi
    syscall
    ret

exit:
    mov rax, 60
    xor rdi, rdi
    syscall

segment readable writeable
buffer rb 20
output_buf rb 20