calculate_sum:
    push rax
    push rbx
    mov rbx, rax
    mov rdi, 0

    .loop:
        mov rax, rbx
        mul rax
        test rbx, 1
        jnz .skip_minus
        neg rax
        .skip_minus:
        add rdi, rax
        dec rbx
        jnz .loop

    pop rbx
    pop rax

    ret