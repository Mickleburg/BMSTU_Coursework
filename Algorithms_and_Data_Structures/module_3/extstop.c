#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define ALPHABET_START 33
#define ALPHABET_END 126
#define ALPHABET_SIZE (ALPHABET_END - ALPHABET_START + 1)

int extended_boyer_moore(char *text, int textlen, char *pattern, int patlen)
{
    int *pos_list[ALPHABET_SIZE];
    int pos_size[ALPHABET_SIZE];
    int pos_index[ALPHABET_SIZE];

    for (int c = 0; c < ALPHABET_SIZE; c++)
    {
        pos_list[c] = NULL;
        pos_size[c] = 0;
        pos_index[c] = 0;
    }

    for (int i = 0; i < patlen; i++)
    {
        int c = pattern[i] - ALPHABET_START;
        if (c >= 0 && c < ALPHABET_SIZE)
            pos_size[c]++;
    }

    for (int c = 0; c < ALPHABET_SIZE; c++)
    {
        if (pos_size[c] > 0)
            pos_list[c] = (int *)malloc(pos_size[c] * sizeof(int));
    }

    for (int i = 0; i < patlen; i++)
    {
        int c = pattern[i] - ALPHABET_START;
        if (c >= 0 && c < ALPHABET_SIZE)
        {
            pos_list[c][pos_index[c]] = i;
            pos_index[c]++;
        }
    }

    int k = patlen - 1;
    while (k < textlen)
    {
        int i = patlen - 1;
        int tk = k;

        while (i >= 0 && pattern[i] == text[tk])
        {
            i--;
            tk--;
        }

        if (i < 0)
        {
            for (int c = 0; c < ALPHABET_SIZE; c++)
            {
                if (pos_list[c] != NULL)
                    free(pos_list[c]);
            }
            return tk + 1;
        }
        else
        {
            int c = text[tk] - ALPHABET_START;
            int shift = 0;

            if (c < 0 || c >= ALPHABET_SIZE || pos_size[c] == 0)
            {
                shift = i + 1;
            }
            else
            {
                int *positions = pos_list[c];
                int count = pos_size[c];
                int left = 0;
                int right = count - 1;
                int j = -1;

                while (left <= right)
                {
                    int mid = (left + right) / 2;
                    if (positions[mid] < i)
                    {
                        j = positions[mid];
                        left = mid + 1;
                    }
                    else
                    {
                        right = mid - 1;
                    }
                }

                if (j != -1)
                    shift = i - j;
                else
                    shift = i + 1;
            }
            k += shift;
        }
    }

    for (int c = 0; c < ALPHABET_SIZE; c++)
    {
        if (pos_list[c] != NULL)
            free(pos_list[c]);
    }
    return textlen;
}

int main(int argc, char *argv[])
{
    if (argc < 3)
    {
        fprintf(stderr, "Not enough arguments\n");
        return 1;
    }

    char *pattern = argv[1];
    char *text = argv[2];
    int patlen = strlen(pattern);
    int textlen = strlen(text);

    int position = extended_boyer_moore(text, textlen, pattern, patlen);
    printf("%d\n", position);

    return 0;
}