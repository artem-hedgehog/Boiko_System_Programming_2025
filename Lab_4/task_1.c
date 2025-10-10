#include <stdio.h>

int main() {
    int n, count = 0;
    scanf("%d", &n);
    
    for (int i = 1; i <= n; i++) {
        if (i % 37 == 0 && i % 13 == 0) {
            count++;
        }
    }
    
    printf("%d\n", count);
    return 0;
}