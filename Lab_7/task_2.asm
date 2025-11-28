format elf64
public _start

; Системные вызовы
SYS_EXIT = 60
SYS_WRITE = 1
SYS_CLONE = 56
SYS_WAIT4 = 61
SYS_FUTEX = 202

; Флаги для clone
THREAD_FLAGS = 0x100  ; CLONE_VM

; Константы
ARRAY_SIZE = 501
NUM_THREADS = 4
STACK_SIZE = 8192

STDOUT = 1

; Константы для futex
FUTEX_WAIT = 0
FUTEX_WAKE = 1

section '.data' writable
    ; Сообщения для вывода результатов
    msg_avg db 'Поток 1 - Среднее арифметическое: ', 0
    msg_third db 'Поток 2 - Третье после максимального: ', 0
    msg_freq db 'Поток 3 - Наиболее частая цифра: ', 0
    msg_div3 db 'Поток 4 - Количество чисел кратных 3: ', 0
    newline db 10, 0
    start_msg db 'Начало работы программы...', 10, 0
    array_msg db 'Массив сгенерирован.', 10, 0
    threads_msg db 'Создаем 4 потока...', 10, 0
    done_msg db 'Все потоки завершили работу.', 10, 0
    
    ; Функции потоков
    thread_functions dq thread_avg, thread_third, thread_freq, thread_div3

    ; Семафор для синхронизации вывода
    print_lock dd 0

section '.bss' writable
    ; Массив случайных чисел
    random_array rq ARRAY_SIZE
    
    ; Стеки для потоков
    thread_stack1 rb STACK_SIZE
    thread_stack2 rb STACK_SIZE  
    thread_stack3 rb STACK_SIZE
    thread_stack4 rb STACK_SIZE
    
    ; PID потоков
    thread_pids rq NUM_THREADS
    
    ; Буфер для вывода чисел
    buffer rb 32

section '.text' executable

; Функция блокировки для вывода
lock_print:
    push rdi
    push rsi
    push rdx
    push rax
    
    mov eax, 1
.lock_loop:
    xchg eax, [print_lock]
    test eax, eax
    jz .locked
    ; Ожидаем разблокировки
    mov rax, SYS_FUTEX
    mov rdi, print_lock
    mov rsi, FUTEX_WAIT
    mov rdx, 1
    mov r10, 0
    mov r8, 0
    mov r9, 0
    syscall
    mov eax, 1
    jmp .lock_loop
    
.locked:
    pop rax
    pop rdx
    pop rsi
    pop rdi
    ret

; Функция разблокировки для вывода
unlock_print:
    push rax
    mov dword [print_lock], 0
    ; Будим ожидающие потоки
    mov rax, SYS_FUTEX
    mov rdi, print_lock
    mov rsi, FUTEX_WAKE
    mov rdx, 1
    mov r10, 0
    mov r8, 0
    mov r9, 0
    syscall
    pop rax
    ret

; Синхронизированная функция вывода строки
print_string_sync:
    push rdi
    push rsi
    push rdx
    push rax
    push rcx
    
    call lock_print
    
    mov rdi, rsi
    call strlen
    mov rdx, rax
    
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    syscall
    
    call unlock_print
    
    pop rcx
    pop rax
    pop rdx
    pop rsi
    pop rdi
    ret

; Функция вывода строки (без синхронизации, для главного процесса)
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

; Преобразование числа в строку
uint_to_str:
    push rbx
    push rdx
    push rdi
    
    mov rbx, 10
    xor rcx, rcx
    
    test rax, rax
    jnz .convert_loop
    mov byte [rdi], '0'
    mov byte [rdi + 1], 0
    jmp .done_convert
    
.convert_loop:
    xor rdx, rdx
    div rbx
    add dl, '0'
    push rdx
    inc rcx
    test rax, rax
    jnz .convert_loop
    
.pop_loop:
    pop rax
    mov [rdi], al
    inc rdi
    loop .pop_loop
    
    mov byte [rdi], 0
.done_convert:
    pop rdi
    pop rdx
    pop rbx
    ret

; Генерация массива случайных чисел
generate_random_array:
    push rdi
    push rsi
    push rcx
    push rbx
    
    mov rsi, start_msg
    call print_string
    
    mov rdi, random_array
    mov rcx, ARRAY_SIZE
    mov rbx, 12345
    
.generate_loop:
    ; Простой ГПСЧ
    mov rax, rbx
    mov rdx, 1103515245
    mul rdx
    add rax, 12345
    mov rbx, rax
    and rax, 0xFF
    
    mov [rdi], rax
    add rdi, 8
    loop .generate_loop
    
    mov rsi, array_msg
    call print_string
    
    pop rbx
    pop rcx
    pop rsi
    pop rdi
    ret

; Поток 1: Среднее арифметическое
thread_avg:
    mov rdi, random_array
    mov rcx, ARRAY_SIZE
    xor rax, rax
    xor rbx, rbx
    
.sum_loop:
    add rax, [rdi]
    inc rbx
    add rdi, 8
    cmp rbx, ARRAY_SIZE
    jl .sum_loop
    
    xor rdx, rdx
    div rbx
    
    mov rsi, msg_avg
    call print_string_sync
    
    mov rdi, buffer
    call uint_to_str
    mov rsi, buffer
    call print_string_sync
    
    mov rsi, newline
    call print_string_sync
    
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

; Поток 2: Третье после максимального
thread_third:
    mov rdi, random_array
    mov rcx, ARRAY_SIZE
    
    mov rax, [rdi]
    mov rbx, [rdi]
    mov rdx, [rdi]
    
    add rdi, 8
    dec rcx
    
.find_max_loop:
    mov r8, [rdi]
    
    cmp r8, rax
    jle .check_max2
    mov rdx, rbx
    mov rbx, rax
    mov rax, r8
    jmp .next
    
.check_max2:
    cmp r8, rbx
    jle .check_max3
    mov rdx, rbx
    mov rbx, r8
    jmp .next
    
.check_max3:
    cmp r8, rdx
    jle .next
    mov rdx, r8
    
.next:
    add rdi, 8
    loop .find_max_loop
    
    mov rsi, msg_third
    call print_string_sync
    
    mov rax, rdx
    mov rdi, buffer
    call uint_to_str
    mov rsi, buffer
    call print_string_sync
    
    mov rsi, newline
    call print_string_sync
    
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

; Поток 3: Наиболее частая цифра
thread_freq:
    sub rsp, 80
    
    mov rdi, rsp
    mov rcx, 10
    xor rax, rax
    rep stosq
    
    mov rdi, random_array
    mov rcx, ARRAY_SIZE
    
.digit_loop:
    mov rax, [rdi]
    mov r8, 10
    
.count_digits:
    xor rdx, rdx
    div r8
    push rax
    mov rax, rdx
    inc qword [rsp + rax * 8 + 80]
    pop rax
    test rax, rax
    jnz .count_digits
    
    add rdi, 8
    loop .digit_loop
    
    xor rax, rax
    xor rbx, rbx
    
    mov rcx, 10
    xor rdx, rdx
    
.find_max_freq:
    mov r8, [rsp + rdx * 8]
    cmp r8, rbx
    jle .next_digit
    mov rbx, r8
    mov rax, rdx
    
.next_digit:
    inc rdx
    loop .find_max_freq
    
    mov rsi, msg_freq
    call print_string_sync
    
    mov rdi, buffer
    call uint_to_str
    mov rsi, buffer
    call print_string_sync
    
    mov rsi, newline
    call print_string_sync
    
    add rsp, 80
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

; Поток 4: Количество чисел, сумма цифр которых кратна 3
thread_div3:
    mov rdi, random_array
    mov rcx, ARRAY_SIZE
    xor rbx, rbx
    
.check_loop:
    mov rax, [rdi]
    xor r9, r9
    
.sum_digits:
    mov r8, 10
    xor rdx, rdx
    div r8
    add r9, rdx
    test rax, rax
    jnz .sum_digits
    
    mov rax, r9
    xor rdx, rdx
    mov r8, 3
    div r8
    test rdx, rdx
    jnz .not_divisible
    inc rbx
    
.not_divisible:
    add rdi, 8
    loop .check_loop
    
    mov rsi, msg_div3
    call print_string_sync
    
    mov rax, rbx
    mov rdi, buffer
    call uint_to_str
    mov rsi, buffer
    call print_string_sync
    
    mov rsi, newline
    call print_string_sync
    
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

; Функция создания потока
; rdi - номер потока (0-3)
create_thread:
    push rdi
    push rsi
    
    ; Выбираем стек в зависимости от номера потока
    cmp rdi, 0
    je .stack1
    cmp rdi, 1
    je .stack2
    cmp rdi, 2
    je .stack3
    jmp .stack4

.stack1:
    mov rsi, thread_stack1
    jmp .got_stack
.stack2:
    mov rsi, thread_stack2
    jmp .got_stack
.stack3:
    mov rsi, thread_stack3
    jmp .got_stack
.stack4:
    mov rsi, thread_stack4

.got_stack:
    add rsi, STACK_SIZE
    
    ; Выбираем функцию потока
    mov r8, [thread_functions + rdi * 8]
    
    ; Создаем поток
    mov rax, SYS_CLONE
    mov rdi, THREAD_FLAGS
    syscall
    
    ; Проверяем результат
    cmp rax, 0
    jl .error
    jz .child_thread
    
    ; Родительский процесс - сохраняем PID
    mov [thread_pids + rdi * 8], rax
    pop rsi
    pop rdi
    ret
    
.child_thread:
    ; Дочерний поток - выполняем функцию
    call r8
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall
    
.error:
    pop rsi
    pop rdi
    ret

; Главная функция
_start:
    call generate_random_array
    
    mov rsi, threads_msg
    call print_string
    
    ; Создаем потоки
    mov rcx, NUM_THREADS
    xor rbx, rbx
    
.create_threads_loop:
    mov rdi, rbx
    push rbx
    push rcx
    call create_thread
    pop rcx
    pop rbx
    
    inc rbx
    loop .create_threads_loop
    
    ; Ожидаем завершения всех потоков
    mov rcx, NUM_THREADS
    xor rbx, rbx
    
.wait_loop:
    mov rax, SYS_WAIT4
    mov rdi, [thread_pids + rbx * 8]
    mov rsi, 0
    mov rdx, 0
    mov r10, 0
    syscall
    
    inc rbx
    cmp rbx, NUM_THREADS
    jl .wait_loop
    
    mov rsi, done_msg
    call print_string
    
    ; Завершаем программу
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall