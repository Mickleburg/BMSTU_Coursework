#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void computePrefixFunction(const char *pattern, int *prefix, int m)
{
    int k = 0;
    prefix[0] = 0;

    for (int i = 1; i < m; i++)
    {
        while (k > 0 && pattern[k] != pattern[i])
        {
            k = prefix[k - 1];
        }
        if (pattern[k] == pattern[i])
        {
            k++;
        }
        prefix[i] = k;
    }
}

void kmpSearch(const char *text, const char *pattern)
{
    int n = strlen(text);
    int m = strlen(pattern);
    int *prefix = (int *)malloc(m * sizeof(int));
    if (!prefix)
    {
        fprintf(stderr, "Memory allocation failed\n");
        return;
    }
    computePrefixFunction(pattern, prefix, m);

    int q = 0;
    for (int i = 0; i < n; i++)
    {
        while (q > 0 && pattern[q] != text[i])
        {
            q = prefix[q - 1];
        }
        if (pattern[q] == text[i])
        {
            q++;
        }
        if (q == m)
        {
            printf("%d ", i - m + 1);
            q = prefix[q - 1];
        }
    }
    free(prefix);
}

int main(int argc, char *argv[])
{
    if (argc != 3)
    {
        fprintf(stderr, "Usage: %s <pattern> <text>\n", argv[0]);
        return 1;
    }
    kmpSearch(argv[2], argv[1]);
    return 0;
}