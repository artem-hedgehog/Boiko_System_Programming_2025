#include <stdio.h>
#include <stdlib.h>

int main(int argc, char *argv[]) {
    // Проверяем количество аргументов
    if (argc != 4) {
        printf("Ошибка: необходимо передать три числа a, b, c\n");
        return 1;
    }

    // Преобразуем аргументы в числа
    int a = atoi(argv[1]);
    int b = atoi(argv[2]);
    int c = atoi(argv[3]);

    // Вычисляем выражение (((a - b) + c) * b)
    int result = ((a - b) + c) * b;

    // Выводим результат
    printf("%d\n", result);

    return 0;
}