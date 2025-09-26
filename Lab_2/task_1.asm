format ELF executable
entry start

segment readable executable
start:
    mov esi, s          ; Указатель на начало строки
    mov ecx, len        ; Длина строки
    add esi, ecx        ; Переход к концу строки
    dec esi             ; Последний символ

reverse_print:
    mov eax, 4          ; sys_write
    mov ebx, 1          ; stdout
    mov edx, 1          ; Длина 1 символ
    mov ecx, esi        ; Текущий символ
    int 0x80
    dec esi             ; Двигаемся к началу
    cmp esi, s          ; До начала строки?
    jge reverse_print

exit:
    mov eax, 1          ; sys_exit
    xor ebx, ebx
    int 0x80

segment readable writeable
s db 'yyblCMJzdDhDeSKlWGmMX', 0
len = $ - s