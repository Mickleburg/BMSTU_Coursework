#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <math.h>

void Get_Prime_Arr(bool *arr, unsigned int sqrt_n)
{
    for (unsigned int i = 0; i < sqrt_n; i++)
    {
        arr[i] = true;
    }
    for (unsigned int i = 2; i < sqrt_n; i++)
    {
        if (arr[i])
        {
            for (unsigned int j = i * i; j < sqrt_n; j += i)
            {
                arr[j] = false;
            }
        }
    }
}

unsigned int Max(unsigned int x1, unsigned int x2)
{
    return (x1 > x2) ? x1 : x2;
}

unsigned int Max_Prime_Div(unsigned int x)
{
    unsigned int max_div = 0;
    while ((x % 2 == 0) && (x > 2))
    {
        x /= 2;
    }
    bool *arr_prime = (bool *)malloc(((unsigned int)(sqrt(x)) + 1) * sizeof(bool));
    Get_Prime_Arr(arr_prime, (unsigned int)(sqrt(x)) + 1);

    for (unsigned int d = 2; d <= sqrt(x); d++)
    {
        if (arr_prime[d]){
            max_div = d;
        }
        while (arr_prime[d] && x % d == 0){
            x /= d;
        }
    }
    if (x > 1){
        max_div = x;
    }
    free(arr_prime);
    return max_div;
}

int main()
{
    int y;
    scanf("%d", &y);
    unsigned int x = abs(y);
    printf("%u\n", Max_Prime_Div(x));
    return 0;
}