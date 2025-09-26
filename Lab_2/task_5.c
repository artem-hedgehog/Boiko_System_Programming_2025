#include <stdio.h>

int main() {
    long long n = 5447175926;
    int sum = 0;
    
    while (n > 0) {
        sum += n % 10;
        n /= 10;
    }
    
    printf("%d\n", sum);
    return 0;
}