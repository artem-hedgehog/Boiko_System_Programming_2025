#include <stdio.h>
#include <stdlib.h>
#include <time.h>

// Объявления ассемблерных функций
extern void add_to_end(long value);
extern long remove_from_begin(void);
extern void fill_random(int count);
extern int count_even(void);
extern int count_prime(void);
extern int count_ends_with_1(void);

// Внешние указатели на функции из ассемблера
extern void* malloc_ptr;
extern void* free_ptr;  
extern void* rand_ptr;

void init_lib() {
    // Инициализация указателей на функции C библиотеки
    malloc_ptr = malloc;
    free_ptr = free;
    rand_ptr = rand;
    
    printf("Library functions initialized\n");
}

void display_menu() {
    printf("\n===Список функций ===\n");
    printf("1. Добавить число в конец очереди\n");
    printf("2. Удалить число из начала очереди\n");
    printf("3. Заполнить очередь случайными числами\n");
    printf("4. Посчитать чётные числа\n");
    printf("5. Посчитать простые числа\n");
    printf("6. Посчитать числа, оканчивающиеся на 1\n");
    printf("7. Выйти\n");
    printf("Ваш выбор: ");
}

int main() {
    srand(time(NULL));
    init_lib();

    int choice, count;
    long value;
    
    printf("Queue program started (ELF64)\n");
    
    while (1) {
        display_menu();
        if (scanf("%d", &choice) != 1) {
            printf("Неправильный ввод\n");
            while (getchar() != '\n'); // clear input buffer
            continue;
        }
        
        switch (choice) {
            case 1:
                printf("Введите значение: ");
                if (scanf("%ld", &value) == 1) {
                    add_to_end(value);
                    printf("Число %ld добавлено в очередь\n", value);
                } else {
                    printf("Некорректное значение\n");
                    while (getchar() != '\n');
                }
                break;
                
            case 2:
                value = remove_from_begin();
                if (value == 0) {
                    printf("Очередь пуста\n");
                } else {
                    printf("Удалено число: %ld\n", value);
                }
                break;
                
            case 3:
                printf("Введите количество случайных чисел: ");
                if (scanf("%d", &count) == 1 && count > 0) {
                    fill_random(count);
                    printf("Добавлено %d случайных чисел\n", count);
                } else {
                    printf("Некорректное число\n");
                    while (getchar() != '\n');
                }
                break;
                
            case 4:
                printf("Количество чётных чисел: %d\n", count_even());
                break;
                
            case 5:
                printf("Количество простых чисел: %d\n", count_prime());
                break;
                
            case 6:
                printf("Количество чисел, оканивающихся на 1: %d\n", count_ends_with_1());
                break;
                
            case 7:
                printf("Выход из программы...\n");
                return 0;
                
            default:
                printf("Некорректный выбор! Пожалуйста, попробуйте заново.\n");
        }
    }
}