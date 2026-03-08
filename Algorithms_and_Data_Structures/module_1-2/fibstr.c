#include<stdio.h>
#include<string.h>
#include<stdlib.h>

char* fibstr(int n);
void Fib_Str_Recursion(int n, char *st1, char *st2);
long long Fib_x(int n, long long x_1, long long x_2);

int main(){
    int n;
    scanf("%d", &n);
    char* fib_str = fibstr(n);
    printf("%s\n", fib_str);
    free(fib_str);
    return 0;
}

char* fibstr(int n){
    if ((n == 1) || (n == 2)){
        char *str_rez = (char *) malloc(2 * sizeof(char));
        if (n == 1){
            str_rez[0] = 'a';
            str_rez[1] = '\0';
        }
        else{
            str_rez[0] = 'b';
            str_rez[1] = '\0';
        }
        return str_rez;
    }
    long long size_str = Fib_x(n - 2, 0, 1) + 1;
    char *str_1 = (char *)malloc(size_str * sizeof(char));
    char *str_2 = (char *)malloc(size_str * sizeof(char));
    str_1[0] = 'a';
    str_1[1] = '\0';
    str_2[0] = 'b';
    str_2[1] = '\0';
    Fib_Str_Recursion(n - 3, str_1, str_2);
    if (n % 2 == 1){
        free(str_2);
        return str_1;
    }
    free(str_1);
    return str_2;
}

void Fib_Str_Recursion(int n, char *st1, char *st2){
    strcat(st1, st2);
    if (n == 0){
        return;
    }
    Fib_Str_Recursion(n - 1, st2, st1);
}

long long Fib_x(int n, long long x_1, long long x_2){
    return  (n < 0) ? 1:
            (n == 0) ? x_1 + x_2:
            Fib_x(n - 1, x_2, x_1 + x_2);
}