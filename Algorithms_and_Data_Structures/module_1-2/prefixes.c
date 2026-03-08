#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void buildPrefixTable(const char *str, int length, int *prefixTable)
{
    int currentLength = 0;
    prefixTable[0] = 0;

    for (int i = 1; i < length; i++)
    {
        while (currentLength > 0 && str[currentLength] != str[i])
        {
            currentLength = prefixTable[currentLength - 1];
        }
        if (str[currentLength] == str[i])
        {
            currentLength++;
        }
        prefixTable[i] = currentLength;
    }
}

int main(int argc, char *argv[])
{
    if (argc != 2)
    {
        printf("Usage: %s <string S>\n", argv[0]);
        return 1;
    }
    const char *S = argv[1];
    int n = strlen(S);
    int *prefixTable = (int *)malloc(n * sizeof(int));
    if (!prefixTable)
    {
        fprintf(stderr, "Error: Memory allocation failed\n");
        return 1;
    }

    buildPrefixTable(S, n, prefixTable);

    for (int i = 0; i < n; i++)
    {
        int len_prefix = i + 1;
        int len_border = prefixTable[i];
        int period = len_prefix - len_border;
        int times = len_prefix / period;

        if (len_prefix % period == 0 && times > 1)
        {
            printf("%d %d\n", len_prefix, times);
        }
    }
    free(prefixTable);
    return 0;
}