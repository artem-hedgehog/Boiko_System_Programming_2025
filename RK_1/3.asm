format ELF64 executable 3
entry start

segment readable executable

start:
    ; Проверяем количество аргументов
    pop rcx
    cmp rcx, 3
    jne exit_error
    
    ; Получаем аргументы
    pop rsi                    ; Имя программы
    pop rdi                    ; Имя каталога-родителя
    pop rsi                    ; Число n
    
    ; Преобразуем n в число
    xor rax, rax
    mov rcx, 10
    call string_to_int
    mov r12, rax               ; Сохраняем n в r12
    
    ; Меняем каталог на родительский
    mov rax, 80                ; sys_chdir
    mov rdi, rdi               ; имя каталога-родителя
    syscall
    test rax, rax
    js exit_error
    
create_dirs:
    test r12, r12
    jz exit_success
    
    ; Создаем каталог "name"
    mov rax, 83                ; sys_mkdir
    lea rdi, [dirname]
    mov rsi, 755o              ; права доступа
    syscall
    test rax, rax
    js exit_error
    
    ; Переходим в созданный каталог
    mov rax, 80                ; sys_chdir
    lea rdi, [dirname]
    syscall
    test rax, rax
    js exit_error
    
    dec r12
    jmp create_dirs

string_to_int:
    ; Преобразует строку в число
    xor rax, rax
    xor rbx, rbx
.convert:
    mov bl, [rsi]
    cmp bl, 0
    je .done
    sub bl, '0'
    imul rax, 10
    add rax, rbx
    inc rsi
    jmp .convert
.done:
    ret

exit_error:
    mov rax, 60
    mov rdi, 1
    syscall

exit_success:
    mov rax, 60
    xor rdi, rdi
    syscall

segment readable writeable
dirname db "name", 0