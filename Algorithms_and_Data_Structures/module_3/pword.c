#include <stdio.h>
#include <string.h>
#include <stdlib.h>

int can_segment(const char *S, const char *T, int pos, int *memo, int s_len, int t_len)
{
    if (pos == t_len)
    {
        return 1;
    }
    if (memo[pos] != -1)
    {
        return memo[pos];
    }
    memo[pos] = 0;
    for (int i = 1; i <= s_len && pos + i <= t_len; i++)
    {
        if (strncmp(S, T + pos, i) == 0)
        {
            if (can_segment(S, T, pos + i, memo, s_len, t_len))
            {
                memo[pos] = 1;
                break;
            }
        }
    }
    return memo[pos];
}

int main(int argc, char *argv[])
{
    if (argc != 3)
    {
        fprintf(stderr, "Usage: ./pword S T\n");
        return 1;
    }

    const char *S = argv[1];
    const char *T = argv[2];
    int s_len = strlen(S);
    int t_len = strlen(T);

    int *memo = malloc((t_len + 1) * sizeof(int));
    if (!memo)
    {
        fprintf(stderr, "Memory allocation failed\n");
        return 1;
    }
    for (int i = 0; i <= t_len; i++)
    {
        memo[i] = -1;
    }

    if (can_segment(S, T, 0, memo, s_len, t_len))
    {
        printf("yes\n");
    }
    else
    {
        printf("no\n");
    }

    free(memo);
    return 0;
}