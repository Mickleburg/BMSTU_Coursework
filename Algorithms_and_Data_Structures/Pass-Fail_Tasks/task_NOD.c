#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_LEN 5000

char *remove_leading_zeros(char *str, int *len)
{
    while (*len > 1 && *str == '0')
    {
        str++;
        (*len)--;
    }
    return str;
}

int is_zero(char *str, int len)
{
    return len == 1 && str[0] == '0';
}

int is_even(char *str, int len)
{
    return str[len - 1] == '0';
}

int compare(char *a, int len_a, char *b, int len_b)
{
    if (len_a < len_b)
        return -1;
    else if (len_a > len_b)
        return 1;
    else
    {
        for (int i = 0; i < len_a; i++)
        {
            if (a[i] < b[i])
                return -1;
            else if (a[i] > b[i])
                return 1;
        }
        return 0;
    }
}

void subtract_inplace(char *a, int *len_a, char *b, int len_b)
{
    int borrow = 0;
    int i = *len_a - 1;
    int j = len_b - 1;

    for (; i >= 0; i--, j--)
    {
        int bit_a = a[i] - '0';
        int bit_b = (j >= 0) ? b[j] - '0' : 0;

        int diff = bit_a - bit_b - borrow;
        if (diff < 0)
        {
            diff += 2;
            borrow = 1;
        }
        else
        {
            borrow = 0;
        }
        a[i] = diff + '0';
    }

    while (*len_a > 1 && a[0] == '0')
    {
        memmove(a, a + 1, *len_a - 1);
        (*len_a)--;
        a[*len_a] = '\0';
    }
}

void shift_right(char *str, int *len)
{
    if (*len > 1)
    {
        str[*len - 1] = '\0';
        (*len)--;
    }
    else
    {
        str[0] = '0';
    }
}

int main(int argc, char *argv[])
{
    if (argc != 3)
    {
        printf("Usage: %s num1 num2\n", argv[0]);
        return 1;
    }

    char buf_u[MAX_LEN];
    char buf_v[MAX_LEN];
    char gcd_result[MAX_LEN * 2];

    strncpy(buf_u, argv[1], MAX_LEN - 1);
    strncpy(buf_v, argv[2], MAX_LEN - 1);
    buf_u[MAX_LEN - 1] = '\0';
    buf_v[MAX_LEN - 1] = '\0';

    int len_u = strlen(buf_u);
    int len_v = strlen(buf_v);

    char *u = remove_leading_zeros(buf_u, &len_u);
    char *v = remove_leading_zeros(buf_v, &len_v);

    if (compare(u, len_u, v, len_v) == 0)
    {
        printf("%s\n", u);
        return 0;
    }

    if (is_zero(u, len_u))
    {
        printf("%s\n", v);
        return 0;
    }

    if (is_zero(v, len_v))
    {
        printf("%s\n", u);
        return 0;
    }

    int shift = 0;

    while (is_even(u, len_u) && is_even(v, len_v))
    {
        shift_right(u, &len_u);
        shift_right(v, &len_v);
        shift++;
        u = remove_leading_zeros(u, &len_u);
        v = remove_leading_zeros(v, &len_v);
    }

    while (is_even(u, len_u))
    {
        shift_right(u, &len_u);
        u = remove_leading_zeros(u, &len_u);
    }

    while (1)
    {
        while (is_even(v, len_v))
        {
            shift_right(v, &len_v);
            v = remove_leading_zeros(v, &len_v);
        }

        int cmp = compare(u, len_u, v, len_v);

        if (cmp == 0)
        {
            break;
        }
        else if (cmp > 0)
        {
            char *temp_str = u;
            int temp_len = len_u;
            u = v;
            len_u = len_v;
            v = temp_str;
            len_v = temp_len;
        }

        subtract_inplace(v, &len_v, u, len_u);
        v = remove_leading_zeros(v, &len_v);
    }

    strncpy(gcd_result, u, len_u);
    int len_gcd = len_u;

    for (int i = 0; i < shift; i++)
    {
        if (len_gcd < MAX_LEN * 2 - 1)
        {
            gcd_result[len_gcd] = '0';
            len_gcd++;
        }
        else
        {
            printf("Result exceeds maximum length\n");
            return 1;
        }
    }

    gcd_result[len_gcd] = '\0';

    printf("%s\n", gcd_result);

    return 0;
}