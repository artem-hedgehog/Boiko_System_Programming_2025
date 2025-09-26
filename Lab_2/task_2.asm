format ELF executable
entry start

segment readable executable
start:
    ; Заполняем память N символами '+'
    mov ecx, 105         ; N = 105
    mov edi, buffer
    mov al, ':'         ; Символ для заполнения
    rep stosb

    ; Выводим матрицу K строк по M символов
    mov esi, buffer     ; Указатель на начало данных
    mov ecx, 15         ; K = 15 строк

print_rows:
    push ecx            ; Сохраняем счетчик строк
    
    ; Вывод одной строки из M символов
    mov ecx, 7          ; M = 7 символов в строке
    mov ebx, 1          ; stdout
    
print_chars:
    push ecx            ; Сохраняем счетчик символов
    mov eax, 4          ; sys_write
    mov ecx, esi        ; Текущий символ
    mov edx, 1          ; Длина 1 символ
    int 0x80
    inc esi             ; Следующий символ
    pop ecx             ; Восстанавливаем счетчик
    loop print_chars
    
    ; Перенос строки
    mov eax, 4
    mov ecx, newline
    mov edx, 1
    int 0x80
    
    pop ecx             ; Восстанавливаем счетчик строк
    loop print_rows

exit:
    mov eax, 1
    xor ebx, ebx
    int 0x80

segment readable writeable
buffer rb 105
newline db 10