#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define ALPHABET_SIZE 94

void make_delta1(int *delta1, char *pattern, int patlen)
{
    for (int i = 0; i < ALPHABET_SIZE; i++)
    {
        delta1[i] = patlen;
    }
    for (int i = 0; i < patlen - 1; i++)
    {
        delta1[pattern[i] - 33] = patlen - 1 - i;
    }
}

void make_suffix(int *suffix, char *pattern, int patlen)
{
    suffix[patlen - 1] = patlen;
    int g = patlen - 1;
    int f = 0;
    for (int i = patlen - 2; i >= 0; i--)
    {
        if (i > g && suffix[i + patlen - 1 - f] < i - g)
        {
            suffix[i] = suffix[i + patlen - 1 - f];
        }
        else
        {
            if (i < g)
            {
                g = i;
            }
            f = i;
            while (g >= 0 && pattern[g] == pattern[g + patlen - 1 - f])
            {
                g--;
            }
            suffix[i] = f - g;
        }
    }
}

void make_delta2(int *delta2, int *suffix, char *pattern, int patlen)
{
    for (int i = 0; i < patlen; i++)
    {
        delta2[i] = patlen;
    }
    int j = 0;
    for (int i = patlen - 1; i >= 0; i--)
    {
        if (suffix[i] == i + 1)
        {
            for (; j < patlen - 1 - i; j++)
            {
                if (delta2[j] == patlen)
                {
                    delta2[j] = patlen - 1 - i;
                }
            }
        }
    }
    for (int i = 0; i <= patlen - 2; i++)
    {
        delta2[patlen - 1 - suffix[i]] = patlen - 1 - i;
    }
}

void boyer_moore(char *text, int textlen, char *pattern, int patlen)
{
    int delta1[ALPHABET_SIZE];
    int *delta2 = (int *)malloc(sizeof(int) * patlen);
    int *suffix = (int *)malloc(sizeof(int) * patlen);

    make_delta1(delta1, pattern, patlen);
    make_suffix(suffix, pattern, patlen);
    make_delta2(delta2, suffix, pattern, patlen);

    int i = patlen - 1;
    while (i < textlen)
    {
        int j = patlen - 1;
        while (j >= 0 && pattern[j] == text[i - (patlen - 1 - j)])
        {
            j--;
        }
        if (j < 0)
        {
            printf("%d\n", i - patlen + 1);
            i += delta2[0];
        }
        else
        {
            int bad_char_shift = delta1[text[i] - 33];
            int good_suffix_shift = delta2[j];
            i += (bad_char_shift > good_suffix_shift) ? bad_char_shift : good_suffix_shift;
        }
    }
    free(delta2);
    free(suffix);
}

int main(int argc, char *argv[])
{
    if (argc < 3)
    {
        printf("Usage: %s pattern text\n", argv[0]);
        return 1;
    }

    char *pattern = argv[1];
    char *text = argv[2];
    int patlen = strlen(pattern);
    int textlen = strlen(text);

    boyer_moore(text, textlen, pattern, patlen);

    return 0;
}