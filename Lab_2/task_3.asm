format ELF executable
entry start

segment readable executable
start:
    mov esi, 1          ; Количество символов в текущей строке (начинаем с 1)
    mov edi, 105         ; Общее количество символов

print_triangle:
    ; Проверяем, достаточно ли символов для полной строки
    cmp edi, esi
    jl print_remaining  ; Если осталось меньше - выводим остаток
    
    ; Вывод строки из esi символов ':'
    mov ecx, esi        ; Количество символов в строке
    mov ebx, 1          ; stdout

print_char:
    push ecx            ; Сохраняем счетчик
    mov eax, 4          ; sys_write
    mov ecx, char       ; Символ '8'
    mov edx, 1          ; Длина 1 символ
    int 0x80
    pop ecx             ; Восстанавливаем счетчик
    loop print_char     ; Повторяем ecx раз
    
    ; Перенос строки
    push eax
    push ebx
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80
    pop ebx
    pop eax
    
    sub edi, esi        ; Уменьшаем общее количество символов
    inc esi             ; Увеличиваем длину следующей строки
    cmp edi, 0
    jg print_triangle   ; Если еще есть символы - продолжаем
    jmp exit

print_remaining:
    ; Вывод оставшихся символов (если есть)
    cmp edi, 0
    jle exit
    
    mov ecx, edi
    mov ebx, 1

print_rest:
    push ecx
    mov eax, 4
    mov ecx, char
    mov edx, 1
    int 0x80
    pop ecx
    loop print_rest
    
    ; Перенос строки после последней строки
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80

exit:
    mov eax, 1
    xor ebx, ebx
    int 0x80

segment readable writeable
char db ':'
newline db 10