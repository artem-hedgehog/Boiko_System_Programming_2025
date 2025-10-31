format ELF64

public add_to_end
public remove_from_begin  
public fill_random
public count_even
public count_prime
public count_ends_with_1

; Экспортируем указатели на функции для C кода
public malloc_ptr
public free_ptr
public rand_ptr

section '.bss' align 16
front dq 0
rear  dq 0

section '.data' align 16
malloc_ptr dq 0
free_ptr   dq 0
rand_ptr   dq 0

section '.text' executable

add_to_end:
    push rbx
    push r12
    mov r12, rdi        ; сохраняем value в r12
    
    mov rdi, 24         ; sizeof(Node) = 24 bytes
    mov rax, [malloc_ptr]
    call rax
    
    test rax, rax
    jz .end
    
    mov [rax], r12      ; node->data = value
    mov qword [rax+8], 0 ; node->next = NULL
    mov rcx, [rear]
    mov [rax+16], rcx   ; node->prev = rear
    
    test rcx, rcx
    jz .first_node
    mov [rcx+8], rax    ; rear->next = node
    jmp .update_rear
    
.first_node:
    mov [front], rax
    
.update_rear:
    mov [rear], rax
.end:
    pop r12
    pop rbx
    ret

remove_from_begin:
    mov rax, [front]
    test rax, rax
    jz .empty
    
    ; Сохраняем данные ДО освобождения памяти
    mov rdx, [rax]      ; сохраняем данные в rdx
    
    mov rcx, [rax+8]    ; next node
    mov [front], rcx
    test rcx, rcx
    jnz .update_prev
    mov qword [rear], 0
    jmp .free
    
.update_prev:
    mov qword [rcx+16], 0
    
.free:
    push rdx            ; сохраняем данные в стеке
    mov rdi, rax
    mov rax, [free_ptr]
    call rax
    pop rax             ; восстанавливаем данные в rax для возврата
    ret
    
.empty:
    xor rax, rax
    ret

fill_random:
    push rbx
    push r12
    mov ebx, edi        ; count
    
.loop:
    test ebx, ebx
    jz .done
    
    mov rax, [rand_ptr]
    call rax
    mov rdi, rax
    call add_to_end
    
    dec ebx
    jmp .loop
    
.done:
    pop r12
    pop rbx
    ret

count_even:
    xor eax, eax
    mov rcx, [front]
    
.loop:
    test rcx, rcx
    jz .done
    
    mov rdx, [rcx]      ; get data
    test rdx, 1         ; check if even
    jnz .next
    inc eax
    
.next:
    mov rcx, [rcx+8]    ; move to next node
    jmp .loop
    
.done:
    ret

count_prime:
    push rbx
    push r12
    push r13
    push r14
    xor r12d, r12d      ; counter
    mov rcx, [front]
    
.outer_loop:
    test rcx, rcx
    jz .done
    
    mov r13, [rcx]      ; get number
    cmp r13, 2
    jl .not_prime
    
    ; Check if number is 2 (special case - only even prime)
    cmp r13, 2
    je .is_prime
    
    ; Check if even
    test r13, 1
    jz .not_prime
    
    ; Check for divisors from 3 to sqrt(n)
    mov rbx, 3
.prime_loop:
    ; Calculate rbx * rbx
    mov rax, rbx
    mul rbx             ; rdx:rax = rbx * rbx
    cmp rax, r13
    ja .is_prime        ; if rbx*rbx > n, it's prime
    
    mov rax, r13
    xor rdx, rdx
    div rbx
    test rdx, rdx
    jz .not_prime       ; found divisor
    
    add rbx, 2          ; check only odd divisors
    jmp .prime_loop
    
.is_prime:
    inc r12d
    
.not_prime:
    mov rcx, [rcx+8]
    jmp .outer_loop
    
.done:
    mov eax, r12d
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

count_ends_with_1:
    push rbx
    push r12
    xor r12d, r12d      ; counter
    mov rcx, [front]
    
.loop:
    test rcx, rcx
    jz .done
    
    mov rax, [rcx]      ; get data
    
    ; Для отрицательных чисел берем модуль
    test rax, rax
    jns .positive       ; если положительное, пропускаем
    neg rax             ; берем модуль отрицательного числа
    
.positive:
    ; Calculate modulo 10 to get last decimal digit
    mov rbx, 10
    xor rdx, rdx
    div rbx             ; rax = quotient, rdx = remainder (last digit)
    
    cmp rdx, 1
    jne .next
    inc r12d
    
.next:
    mov rcx, [rcx+8]
    jmp .loop
    
.done:
    mov eax, r12d
    pop r12
    pop rbx
    ret