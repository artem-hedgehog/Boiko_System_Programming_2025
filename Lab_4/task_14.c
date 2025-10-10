#include <stdio.h>

int main() {
    unsigned long long n, x, square, modulus, temp;
    scanf("%llu", &n);
    
    for (x = 1; x <= n; x++) {
        square = x * x;
        modulus = 1;
        temp = x;
        while (temp > 0) {
            modulus *= 10;
            temp /= 10;
        }
        if (square % modulus == x) {
            printf("%llu\n", x);
        }
    }
    
    return 0;
}