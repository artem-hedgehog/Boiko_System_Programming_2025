format ELF64

public _start

; Подключаем функции из библиотеки
include 'func.asm'

section '.data' writable
    ; Сообщение об ошибке, если аргумент отсутствует
    error_msg db "Ошибка: не указан символ.", 0xA, 0
    ; Буфер для преобразования числа в строку (максимум 3 цифры для ASCII)
    buffer db 4 dup(0)

section '.text' executable

_start:
    ; Получаем количество аргументов командной строки
    pop rcx
    ; Проверяем, что есть хотя бы один аргумент (кроме имени программы)
    cmp rcx, 2
    jl .error      ; Если аргументов меньше 2, выводим ошибку

    ; Пропускаем первый аргумент (имя программы)
    pop rsi
    ; Получаем второй аргумент (введенный символ)
    pop rsi

    ; Проверяем, что аргумент состоит из одного символа
    cmp byte [rsi+1], 0
    jne .error     ; Если есть второй символ, выводим ошибку

    ; Преобразуем символ в ASCII-код
    movzx rax, byte [rsi]
    ; Преобразуем число в строку
    mov rdi, buffer
    call number_to_str

    ; Выводим результат
    mov rsi, buffer
    call print_str
    call new_line
    call exit

.error:
    ; Выводим сообщение об ошибке и завершаем программу
    mov rsi, error_msg
    call print_str
    call exit

; Функция преобразования числа в строку
; Вход: RAX - число, RDI - буфер для строки
number_to_str:
    push rbx
    push rcx
    push rdx
    push rsi

    mov rsi, rdi   ; Сохраняем начало буфера
    mov rcx, 0     ; Счетчик цифр

    ; Обрабатываем случай числа 0
    test rax, rax
    jnz .loop
    mov byte [rdi], '0'
    inc rdi
    jmp .finish

.loop:
    ; Делим число на 10
    xor rdx, rdx
    mov rbx, 10
    div rbx
    ; Преобразуем остаток в символ
    add dl, '0'
    push rdx       ; Сохраняем символ в стеке
    inc rcx
    ; Продолжаем, пока число не станет 0
    test rax, rax
    jnz .loop

    ; Извлекаем символы из стека в обратном порядке
.pop_loop:
    pop rax
    mov [rdi], al
    inc rdi
    loop .pop_loop

.finish:
    ; Добавляем нулевой терминатор
    mov byte [rdi], 0
    mov rdi, rsi   ; Восстанавливаем начало буфера
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret