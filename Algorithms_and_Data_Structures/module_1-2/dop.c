#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdbool.h>

#define SIZE 1000

struct word
{
    char *ptr_start;
    char *ptr_end;
    unsigned int k; // кол-во слов, превосходимых этим словом по длине
};

void csort(char *src, char *dest)
{
    unsigned int k = 0;
    int len1, len2;
    struct word *words = (struct word *)malloc(SIZE * sizeof(struct word));
    struct word *words_start = words;
    char *src_start = src;
    bool in_word = false;

    while (*src_start)
    {
        if ((*src_start) == ' ')
        {
            if (in_word)
            {
                words_start->ptr_end = src_start;
                in_word = false;
                words_start++;
                k++;
            }
        }
        else
        {
            if (!in_word)
            {
                words_start->ptr_start = src_start;
                words_start->k = 0;
                in_word = true;
            }
        }
        src_start++;
    }
    if (in_word)
    {
        words_start->ptr_end = src_start;
        words_start->k = 0;
        k++;
        words_start++;
        words_start = NULL;
    }

    for (unsigned int i = 0; i < k - 1; i++)
    {
        for (unsigned int j = i + 1; j < k; j++)
        {
            len1 = (char *)((words + j)->ptr_end) - (char *)((words + j)->ptr_start);
            len2 = (char *)((words + i)->ptr_end) - (char *)((words + i)->ptr_start);
            if (len1 - len2 >= 0)
            {
                (words + j)->k++;
            }
            else
            {
                (words + i)->k++;
            }
        }
    }

    unsigned int j, len;
    for (unsigned int i = 0; i < k; i++)
    {
        j = 0;
        while ((words + j)->k != i)
        {
            j++;
        }

        len = (char *)(words + j)->ptr_end - (char *)(words + j)->ptr_start;
        strncpy(dest, (words + j)->ptr_start, len);
        dest += len;
        (*dest) = ' ';
        dest++;
    }
    dest--;
    (*dest) = '\0';

    free(words);
}

int main()
{
    char *str = (char *)malloc(SIZE * sizeof(char));
    char *new_str = (char *)malloc(SIZE * sizeof(char));
    fgets(str, SIZE, stdin);
    unsigned int len = strlen(str);
    str[len - 1] = '\0';

    csort(str, new_str);
    printf("%s\n", new_str);

    free(str);
    free(new_str);
    return 0;
}
