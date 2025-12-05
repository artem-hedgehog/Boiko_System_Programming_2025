format ELF64

public _start

SYS_EXIT    = 60
SYS_WRITE   = 1
SYS_CLONE   = 56
SYS_WAITPID = 61
SYS_TIME    = 201

CLONE_VM     = 0x00000100


STDOUT = 1

section '.data' writable
    msg_even_sum db 'Дочерний процесс 1 - Сумма элементов с чётными номерами: ', 0
    msg_odd_sum  db 'Дочерний процесс 2 - Сумма элементов с нечётными номерами: ', 0
    msg_error_args db 'Ошибка: укажите количество элементов N как параметр', 10, 0
    msg_error_number db 'Ошибка: N должно быть положительным числом в диапазоне 1-1000', 10, 0
    newline db 10, 0

    buffer rb 32

section '.bss' writable
    array rb 1000
    array_size dq 0

    pid1 dq 0
    pid2 dq 0

    stack1 rb 65536
    stack2 rb 65536

    rand_seed dq 0

section '.text' executable

print_string:
    push rdi
    push rsi
    push rdx
    push rax

    mov rdx, 0
.find_length:
    cmp byte [rsi + rdx], 0
    je .print
    inc rdx
    jmp .find_length
    
.print:
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    syscall
    
    pop rax
    pop rdx
    pop rsi
    pop rdi
    ret

int_to_str:
    push rbx
    push rdx
    push rdi
    
    mov rbx, 10
    xor rcx, rcx

    test rax, rax
    jnz .convert_loop
    mov byte [rdi], '0'
    mov byte [rdi + 1], 0
    jmp .done
    
.convert_loop:
    xor rdx, rdx
    div rbx
    add dl, '0'
    push rdx
    inc rcx
    test rax, rax
    jnz .convert_loop

    mov rbx, rdi
.pop_loop:
    pop rax
    mov [rbx], al
    inc rbx
    loop .pop_loop
    
    mov byte [rbx], 0
    
.done:
    pop rdi
    pop rdx
    pop rbx
    ret

str_to_int:
    xor rax, rax
    
.convert:
    movzx rdx, byte [rdi]
    test rdx, rdx
    jz .done
    
    sub rdx, '0'
    imul rax, 10
    add rax, rdx
    
    inc rdi
    jmp .convert
    
.done:
    ret

fill_array:
    push rdi
    push rcx

    mov rax, SYS_TIME
    xor rdi, rdi
    syscall
    mov [rand_seed], rax
    
    mov rdi, array
    mov rcx, [array_size]
    
.fill:
    mov rax, [rand_seed]
    imul rax, 1103515245
    add rax, 12345
    and rax, 0x7FFFFFFF
    mov [rand_seed], rax

    xor rdx, rdx
    mov rbx, 100
    div rbx

    mov [rdi], dl
    inc rdi
    
    loop .fill
    
    pop rcx
    pop rdi
    ret

; Дочерний процесс 1: сумма четных элементов
child1:
    mov rdi, array
    mov rcx, [array_size]
    xor rax, rax    ; индекс
    xor rbx, rbx    ; сумма
    
.sum_even:
    test rax, 1
    jnz .next_even
    
    xor rdx, rdx
    mov dl, [rdi + rax]
    add rbx, rdx
    
.next_even:
    inc rax
    cmp rax, rcx
    jl .sum_even
    
    mov rsi, msg_even_sum
    call print_string
    
    mov rax, rbx
    mov rdi, buffer
    call int_to_str
    mov rsi, buffer
    call print_string
    
    mov rsi, newline
    call print_string

    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

; Дочерний процесс 2: сумма нечетных элементов
child2:
    mov rdi, array
    mov rcx, [array_size]
    xor rax, rax    ; индекс
    xor rbx, rbx    ; сумма
    
.sum_odd:
    test rax, 1
    jz .next_odd
    
    xor rdx, rdx
    mov dl, [rdi + rax]
    add rbx, rdx
    
.next_odd:
    inc rax
    cmp rax, rcx
    jl .sum_odd

    mov rsi, msg_odd_sum
    call print_string
    
    mov rax, rbx
    mov rdi, buffer
    call int_to_str
    mov rsi, buffer
    call print_string
    
    mov rsi, newline
    call print_string

    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

_start:
    pop rcx
    cmp rcx, 2
    jge .get_arg
    
    mov rsi, msg_error_args
    call print_string
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall
    
.get_arg:
    pop rsi  
    pop rsi  
    mov rdi, rsi
    call str_to_int

    cmp rax, 1
    jl .error_size
    cmp rax, 1000
    jg .error_size
    
    mov [array_size], rax

    call fill_array
    
    ; Создаем первый процесс
    mov rax, SYS_CLONE
    mov rdi, CLONE_VM
    lea rsi, [stack1 + 65536]
    xor rdx, rdx
    xor r10, r10
    syscall
    
    cmp rax, 0
    jl .error_clone
    je child1
    
    mov [pid1], rax
    
    ; Создаем второй процесс
    mov rax, SYS_CLONE
    mov rdi, CLONE_VM
    lea rsi, [stack2 + 65536]
    xor rdx, rdx
    xor r10, r10
    syscall
    
    cmp rax, 0
    jl .error_clone
    je child2
    
    mov [pid2], rax

    mov rax, SYS_WAITPID
    mov rdi, [pid1]
    mov rsi, 0
    mov rdx, 0
    mov r10, 0
    syscall
    
    mov rax, SYS_WAITPID
    mov rdi, [pid2]
    mov rsi, 0
    mov rdx, 0
    mov r10, 0
    syscall

    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall
    
.error_size:
    mov rsi, msg_error_number
    call print_string
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall
    
.error_clone:
    mov rax, SYS_EXIT
    mov rdi, 2
    syscall