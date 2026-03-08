#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_N 100000

const char *T;

typedef struct
{
    int index;
    int rank[2];
} Suffix;

int cmp_suffix(const void *a, const void *b)
{
    Suffix *sa = (Suffix *)a;
    Suffix *sb = (Suffix *)b;

    if (sa->rank[0] != sb->rank[0])
        return sa->rank[0] - sb->rank[0];
    else
        return sa->rank[1] - sb->rank[1];
}

int compare_positions(const void *a, const void *b)
{
    int pos1 = *(const int *)a;
    int pos2 = *(const int *)b;
    return pos1 - pos2;
}

int *build_suffix_array(const char *txt, int n)
{
    Suffix *suffixes = (Suffix *)malloc(n * sizeof(Suffix));
    int *suffix_array = (int *)malloc(n * sizeof(int));

    for (int i = 0; i < n; i++)
    {
        suffixes[i].index = i;
        suffixes[i].rank[0] = txt[i];
        suffixes[i].rank[1] = ((i + 1) < n) ? txt[i + 1] : -1;
    }

    qsort(suffixes, n, sizeof(Suffix), cmp_suffix);

    int *ind = (int *)malloc(n * sizeof(int));

    for (int k = 4; k < 2 * n; k *= 2)
    {
        int rank = 0;
        int prev_rank = suffixes[0].rank[0];
        suffixes[0].rank[0] = rank;
        ind[suffixes[0].index] = 0;

        for (int i = 1; i < n; i++)
        {
            if (suffixes[i].rank[0] == prev_rank &&
                suffixes[i].rank[1] == suffixes[i - 1].rank[1])
            {
                prev_rank = suffixes[i].rank[0];
                suffixes[i].rank[0] = rank;
            }
            else
            {
                prev_rank = suffixes[i].rank[0];
                suffixes[i].rank[0] = ++rank;
            }
            ind[suffixes[i].index] = i;
        }

        for (int i = 0; i < n; i++)
        {
            int next_index = suffixes[i].index + k / 2;
            suffixes[i].rank[1] = (next_index < n) ? suffixes[ind[next_index]].rank[0] : -1;
        }

        qsort(suffixes, n, sizeof(Suffix), cmp_suffix);
    }

    for (int i = 0; i < n; i++)
        suffix_array[i] = suffixes[i].index;

    free(suffixes);
    free(ind);

    return suffix_array;
}

int lower_bound(int *suffix_array, int size, const char *S, int len_S)
{
    int left = 0;
    int right = size;
    while (left < right)
    {
        int mid = (left + right) / 2;
        int cmp = strncmp(T + suffix_array[mid], S, len_S);
        if (cmp < 0)
        {
            left = mid + 1;
        }
        else
        {
            right = mid;
        }
    }
    return left;
}

int upper_bound(int *suffix_array, int size, const char *S, int len_S)
{
    int left = 0;
    int right = size;
    while (left < right)
    {
        int mid = (left + right) / 2;
        int cmp = strncmp(T + suffix_array[mid], S, len_S);
        if (cmp <= 0)
        {
            left = mid + 1;
        }
        else
        {
            right = mid;
        }
    }
    return left;
}

int main(int argc, char *argv[])
{
    if (argc != 3)
    {
        printf("Неверное количество аргументов\n");
        return 1;
    }

    const char *S = argv[1];
    T = argv[2];

    int len_T = strlen(T);
    int len_S = strlen(S);

    if (len_T == 0 || len_S == 0 || len_S > len_T)
    {
        return 0;
    }

    int *suffix_array = build_suffix_array(T, len_T);
    if (!suffix_array)
    {
        printf("Ошибка выделения памяти\n");
        return 1;
    }

    int first = lower_bound(suffix_array, len_T, S, len_S);
    int last = upper_bound(suffix_array, len_T, S, len_S);

    if (first == last)
    {
        free(suffix_array);
        return 0;
    }

    int count = last - first;
    int *positions = (int *)malloc(count * sizeof(int));
    if (!positions)
    {
        printf("Ошибка выделения памяти\n");
        free(suffix_array);
        return 1;
    }

    for (int i = 0; i < count; i++)
    {
        positions[i] = suffix_array[first + i];
    }

    qsort(positions, count, sizeof(int), compare_positions);

    for (int i = 0; i < count; i++)
    {
        printf("%d\n", positions[i]);
    }

    free(suffix_array);
    free(positions);

    return 0;
}