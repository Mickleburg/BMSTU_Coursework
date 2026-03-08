#include <stdio.h>
#include <stdlib.h>

typedef long long ll;

int cmpfunc(const void *a, const void *b)
{
    if (*(ll *)a < *(ll *)b)
        return -1;
    else if (*(ll *)a > *(ll *)b)
        return 1;
    else
        return 0;
}

int main()
{
    int n;
    scanf("%d", &n);

    ll *prefix_xor = (ll *)malloc((n + 1) * sizeof(ll));
    prefix_xor[0] = 0;

    for (int i = 1; i <= n; i++)
    {
        ll num;
        scanf("%lld", &num);
        prefix_xor[i] = prefix_xor[i - 1] ^ num;
    }

    qsort(prefix_xor, n + 1, sizeof(ll), cmpfunc);

    ll count = 0;
    ll current = prefix_xor[0];
    ll occurrences = 1;

    for (int i = 1; i <= n; i++)
    {
        if (prefix_xor[i] == current)
        {
            occurrences++;
        }
        else
        {
            count += occurrences * (occurrences - 1) / 2;
            current = prefix_xor[i];
            occurrences = 1;
        }
    }
    count += occurrences * (occurrences - 1) / 2;

    printf("%lld\n", count);

    free(prefix_xor);
    return 0;
}